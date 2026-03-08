defmodule Backend.Documents.DocServerTest do
  use Backend.DataCase

  import Backend.Factory

  alias Backend.Documents
  alias Backend.Documents.DocServer
  alias Phoenix.Socket.Broadcast

  setup do
    # Stop all DocServer processes between tests
    Backend.DocSupervisor
    |> DynamicSupervisor.which_children()
    |> Enum.each(fn {_, pid, _, _} -> DynamicSupervisor.terminate_child(Backend.DocSupervisor, pid) end)

    :ok
  end

  describe "find_or_start/1" do
    test "starts a new DocServer for a valid document" do
      document = insert(:document)
      assert {:ok, pid} = DocServer.find_or_start(document.id)
      assert Process.alive?(pid)
    end

    test "returns the existing process on subsequent calls" do
      document = insert(:document)
      {:ok, pid1} = DocServer.find_or_start(document.id)
      {:ok, pid2} = DocServer.find_or_start(document.id)
      assert pid1 == pid2
    end

    test "starts separate processes for different documents" do
      doc1 = insert(:document)
      doc2 = insert(:document)
      {:ok, pid1} = DocServer.find_or_start(doc1.id)
      {:ok, pid2} = DocServer.find_or_start(doc2.id)
      assert pid1 != pid2
    end

    test "fails when document does not exist" do
      assert {:error, _} = DocServer.find_or_start(0)
    end
  end

  describe "init/2" do
    test "restores persisted yjs_state on startup" do
      document = insert(:document)

      # Write some content into a Yjs doc and persist it
      doc = Yex.Doc.new()
      text = Yex.Doc.get_text(doc, "root")
      Yex.Text.insert(text, 0, "hello world")
      {:ok, encoded} = Yex.encode_state_as_update(doc)
      Documents.update_yjs_state(document.id, encoded)

      # Start the DocServer — it should load the persisted state
      {:ok, pid} = DocServer.find_or_start(document.id)

      # Send a sync step 1 to get the server's state back
      {:ok, step1} = Yex.Sync.message_encode({:sync, {:sync_step1, <<0>>}})
      {:ok, replies} = DocServer.process_message_v1(pid, step1, self())

      # Decode the sync step 2 reply and apply to a fresh doc
      client_doc = Yex.Doc.new()

      for reply <- replies do
        case Yex.Sync.message_decode(reply) do
          {:ok, {:sync, {:sync_step2, update}}} ->
            Yex.apply_update(client_doc, update)

          _ ->
            :ok
        end
      end

      client_text = Yex.Doc.get_text(client_doc, "root")
      assert Yex.Text.to_string(client_text) == "hello world"
    end
  end

  describe "get_encoded_state/1" do
    test "returns the current Yjs state as a binary" do
      document = insert(:document)
      {:ok, pid} = DocServer.find_or_start(document.id)

      {:ok, encoded} = DocServer.get_encoded_state(pid)
      assert is_binary(encoded)
    end

    test "reflects applied updates" do
      document = insert(:document)
      {:ok, pid} = DocServer.find_or_start(document.id)

      # Apply an update
      update_doc = Yex.Doc.new()
      text = Yex.Doc.get_text(update_doc, "root")
      Yex.Text.insert(text, 0, "encoded state test")
      {:ok, update} = Yex.encode_state_as_update(update_doc)
      {:ok, message} = Yex.Sync.message_encode({:sync, {:sync_step2, update}})
      DocServer.process_message_v1(pid, message, self())
      :timer.sleep(50)

      # Read back and verify
      {:ok, encoded} = DocServer.get_encoded_state(pid)
      verify_doc = Yex.Doc.new()
      Yex.apply_update(verify_doc, encoded)
      verify_text = Yex.Doc.get_text(verify_doc, "root")
      assert Yex.Text.to_string(verify_text) == "encoded state test"
    end
  end

  describe "apply_update/2" do
    test "applies a Yjs update and persists it" do
      document = insert(:document)
      {:ok, pid} = DocServer.find_or_start(document.id)

      update_doc = Yex.Doc.new()
      text = Yex.Doc.get_text(update_doc, "root")
      Yex.Text.insert(text, 0, "applied update")
      {:ok, update} = Yex.encode_state_as_update(update_doc)

      :ok = DocServer.apply_update(pid, update)
      :timer.sleep(50)

      # Verify persisted
      updated_doc = Documents.get(document.id)
      assert updated_doc.yjs_state

      verify_doc = Yex.Doc.new()
      Yex.apply_update(verify_doc, updated_doc.yjs_state)
      verify_text = Yex.Doc.get_text(verify_doc, "root")
      assert Yex.Text.to_string(verify_text) == "applied update"
    end

    test "broadcasts the update to subscribers" do
      document = insert(:document)
      topic = Documents.topic(document.id)
      BackendWeb.Endpoint.subscribe(topic)

      {:ok, pid} = DocServer.find_or_start(document.id)

      update_doc = Yex.Doc.new()
      text = Yex.Doc.get_text(update_doc, "root")
      Yex.Text.insert(text, 0, "broadcast via apply_update")
      {:ok, update} = Yex.encode_state_as_update(update_doc)

      :ok = DocServer.apply_update(pid, update)

      assert_receive %Broadcast{
        topic: ^topic,
        event: "yjs",
        payload: %{"data" => data}
      }

      assert is_binary(data)
    end
  end

  describe "handle_update_v1/4" do
    test "persists state to the database after an update" do
      document = insert(:document)
      {:ok, pid} = DocServer.find_or_start(document.id)

      # Apply an update via the sync protocol
      update_doc = Yex.Doc.new()
      text = Yex.Doc.get_text(update_doc, "root")
      Yex.Text.insert(text, 0, "persisted content")
      {:ok, update} = Yex.encode_state_as_update(update_doc)
      {:ok, message} = Yex.Sync.message_encode({:sync, {:sync_step2, update}})

      DocServer.process_message_v1(pid, message, self())

      # Give the async cast time to process
      :timer.sleep(50)

      # Verify the state was persisted
      updated_doc = Documents.get(document.id)
      assert updated_doc.yjs_state

      # Verify the persisted state contains the text
      verify_doc = Yex.Doc.new()
      Yex.apply_update(verify_doc, updated_doc.yjs_state)
      verify_text = Yex.Doc.get_text(verify_doc, "root")
      assert Yex.Text.to_string(verify_text) == "persisted content"
    end

    test "broadcasts update to the document topic" do
      document = insert(:document)
      topic = Documents.topic(document.id)
      BackendWeb.Endpoint.subscribe(topic)

      {:ok, pid} = DocServer.find_or_start(document.id)

      # Apply an update with a different origin PID so broadcast_from
      # doesn't exclude the test process (which is the subscriber)
      origin = spawn(fn -> :ok end)

      update_doc = Yex.Doc.new()
      text = Yex.Doc.get_text(update_doc, "root")
      Yex.Text.insert(text, 0, "broadcast test")
      {:ok, update} = Yex.encode_state_as_update(update_doc)
      {:ok, message} = Yex.Sync.message_encode({:sync, {:sync_step2, update}})

      DocServer.process_message_v1(pid, message, origin)

      assert_receive %Broadcast{
        topic: ^topic,
        event: "yjs",
        payload: %{"data" => data}
      }

      assert is_binary(data)
    end
  end
end
