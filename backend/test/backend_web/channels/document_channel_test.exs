defmodule BackendWeb.DocumentChannelTest do
  use BackendWeb.ChannelCase

  import Backend.Factory

  setup do
    # Clean up any DocServer processes between tests
    Backend.DocSupervisor
    |> DynamicSupervisor.which_children()
    |> Enum.each(fn {_, pid, _, _} ->
      DynamicSupervisor.terminate_child(Backend.DocSupervisor, pid)
    end)

    {:ok, _, socket} =
      BackendWeb.UserSocket
      |> socket("", %{})
      |> subscribe_and_join(BackendWeb.DocumentChannel, "document:#{insert(:document).id}")

    %{socket: socket}
  end

  describe "join/3" do
    test "joins successfully for a valid document" do
      document = insert(:document)

      {:ok, _, _socket} =
        BackendWeb.UserSocket
        |> socket("", %{})
        |> subscribe_and_join(BackendWeb.DocumentChannel, "document:#{document.id}")
    end

    test "starts a DocServer on join" do
      document = insert(:document)

      assert Registry.lookup(Backend.DocRegistry, document.id) == []

      {:ok, _, _socket} =
        BackendWeb.UserSocket
        |> socket("", %{})
        |> subscribe_and_join(BackendWeb.DocumentChannel, "document:#{document.id}")

      assert [{pid, _}] = Registry.lookup(Backend.DocRegistry, document.id)
      assert Process.alive?(pid)
    end

    test "reuses existing DocServer for same document" do
      document = insert(:document)
      {:ok, _} = Backend.Documents.DocServer.find_or_start(document.id)
      [{pid_before, _}] = Registry.lookup(Backend.DocRegistry, document.id)

      {:ok, _, _socket} =
        BackendWeb.UserSocket
        |> socket("", %{})
        |> subscribe_and_join(BackendWeb.DocumentChannel, "document:#{document.id}")

      [{pid_after, _}] = Registry.lookup(Backend.DocRegistry, document.id)
      assert pid_before == pid_after
    end

    test "fails for a non-existent document" do
      assert {:error, %{reason: "failed to start document server"}} =
               BackendWeb.UserSocket
               |> socket("", %{})
               |> subscribe_and_join(BackendWeb.DocumentChannel, "document:0")
    end
  end

  describe "handle_in yjs sync" do
    test "replies with sync step 2 when receiving sync step 1", %{socket: socket} do
      # Build a sync step 1 message (client sends its state vector)
      {:ok, message} = Yex.Sync.message_encode({:sync, {:sync_step1, <<0>>}})
      encoded = Base.encode64(message)

      ref = push(socket, "yjs", %{"data" => encoded})
      # sync step 1 is a call, so the channel doesn't reply on the push
      # but it pushes yjs messages back
      refute_reply ref, _status

      # Server should push back sync step 2 + its own sync step 1
      assert_push "yjs", %{"data" => reply_data}
      reply_binary = Base.decode64!(reply_data)
      assert {:ok, {:sync, {:sync_step2, _update}}} = Yex.Sync.message_decode(reply_binary)
    end

    test "accepts sync step 2 / updates without reply", %{socket: socket} do
      # Build a document update
      doc = Yex.Doc.new()
      text = Yex.Doc.get_text(doc, "root")
      Yex.Text.insert(text, 0, "hello")
      {:ok, update} = Yex.encode_state_as_update(doc)

      {:ok, message} = Yex.Sync.message_encode({:sync, {:sync_step2, update}})
      encoded = Base.encode64(message)

      push(socket, "yjs", %{"data" => encoded})

      # sync step 2 is a cast — no push back to the sender
      refute_push "yjs", _payload, 100
    end

    test "persists document state after receiving an update", %{socket: socket} do
      document_id = socket.assigns.document_id

      # Send an update
      doc = Yex.Doc.new()
      text = Yex.Doc.get_text(doc, "root")
      Yex.Text.insert(text, 0, "channel test")
      {:ok, update} = Yex.encode_state_as_update(doc)

      {:ok, message} = Yex.Sync.message_encode({:sync, {:sync_step2, update}})
      push(socket, "yjs", %{"data" => Base.encode64(message)})

      # Wait for async processing
      :timer.sleep(50)

      # Verify state was persisted
      updated = Backend.Documents.get(document_id)
      assert updated.yjs_state

      verify_doc = Yex.Doc.new()
      Yex.apply_update(verify_doc, updated.yjs_state)
      verify_text = Yex.Doc.get_text(verify_doc, "root")
      assert Yex.Text.to_string(verify_text) == "channel test"
    end
  end

  describe "handle_in yjs broadcast" do
    test "broadcasts updates to other clients", %{socket: socket} do
      document_id = socket.assigns.document_id

      # Join a second client to the same document
      {:ok, _, _socket2} =
        BackendWeb.UserSocket
        |> socket("", %{})
        |> subscribe_and_join(BackendWeb.DocumentChannel, "document:#{document_id}")

      # Send an update from the first client
      doc = Yex.Doc.new()
      text = Yex.Doc.get_text(doc, "root")
      Yex.Text.insert(text, 0, "broadcast")
      {:ok, update} = Yex.encode_state_as_update(doc)

      {:ok, message} = Yex.Sync.message_encode({:sync, {:sync_step2, update}})
      push(socket, "yjs", %{"data" => Base.encode64(message)})

      # The broadcast should arrive (we're subscribed to the topic)
      assert_broadcast "yjs", %{"data" => _data}
    end
  end
end
