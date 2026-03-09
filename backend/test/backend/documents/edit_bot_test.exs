defmodule Backend.Documents.EditBotTest do
  use Backend.DataCase

  import Backend.Factory

  alias Backend.Documents.DocServer
  alias Backend.Documents.EditBot

  setup do
    Backend.DocSupervisor
    |> DynamicSupervisor.which_children()
    |> Enum.each(fn {_, pid, _, _} ->
      DynamicSupervisor.terminate_child(Backend.DocSupervisor, pid)
    end)

    :ok
  end

  describe "start_link/1" do
    test "starts the GenServer for a valid document" do
      document = insert(:document)
      insert(:organisation_user, user: insert(:agent), organisation: document.organisation)
      assert {:ok, pid} = EditBot.start_link(document_id: document.id)
      assert Process.alive?(pid)

      on_exit(fn ->
        if Process.alive?(pid), do: GenServer.stop(pid, :normal, 5_000)
      end)
    end

    test "fails for a non-existent document" do
      Process.flag(:trap_exit, true)
      assert {:error, _} = EditBot.start_link(document_id: 0)
    end

    test "fails when no agent exists for the organisation" do
      Process.flag(:trap_exit, true)
      document = insert(:document)
      assert {:error, :not_found} = EditBot.start_link(document_id: document.id)
    end
  end

  describe "execute_command/2" do
    test "applies a sidecar edit to the document" do
      document = insert(:document)
      insert(:organisation_user, user: insert(:agent), organisation: document.organisation)
      {:ok, pid} = EditBot.start_link(document_id: document.id)

      on_exit(fn ->
        if Process.alive?(pid), do: GenServer.stop(pid, :normal, 5_000)
      end)

      assert :ok = EditBot.execute_command(pid, "append_hello")

      # Verify the document was updated
      {:ok, doc_server} = DocServer.find_or_start(document.id)
      {:ok, encoded} = DocServer.get_encoded_state(doc_server)

      verify_doc = Yex.Doc.new()
      Yex.apply_update(verify_doc, encoded)

      # The sidecar should have appended "hello world" as a paragraph.
      # The Lexical v1 binding stores content in an XmlText named "root".
      # We can verify the text content is present by checking the XmlText.
      root = Yex.Doc.get_xml_fragment(verify_doc, "root")
      text = Yex.XmlFragment.to_string(root)
      assert text =~ "hello world"
    end

    test "returns error for unknown commands" do
      document = insert(:document)
      insert(:organisation_user, user: insert(:agent), organisation: document.organisation)
      {:ok, pid} = EditBot.start_link(document_id: document.id)

      on_exit(fn ->
        if Process.alive?(pid), do: GenServer.stop(pid, :normal, 5_000)
      end)

      assert {:error, "unknown command: nonexistent"} =
               EditBot.execute_command(pid, "nonexistent")
    end
  end

  describe "sidecar lifecycle" do
    test "stops when the sidecar process exits unexpectedly" do
      Process.flag(:trap_exit, true)
      document = insert(:document)
      insert(:organisation_user, user: insert(:agent), organisation: document.organisation)
      {:ok, pid} = EditBot.start_link(document_id: document.id)

      ref = Process.monitor(pid)

      # Get the port and find the OS pid of the sidecar process, then kill it
      {:links, links} = Process.info(pid, :links)

      port =
        Enum.find(links, fn
          p when is_port(p) -> true
          _ -> false
        end)

      assert port

      {:os_pid, os_pid} = Port.info(port, :os_pid)
      System.cmd("kill", ["-9", to_string(os_pid)])

      assert_receive {:DOWN, ^ref, :process, ^pid, _reason}, 5_000
    end
  end
end
