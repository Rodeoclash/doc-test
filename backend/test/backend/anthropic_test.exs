defmodule Backend.AnthropicTest do
  use ExUnit.Case, async: true

  alias Backend.Anthropic.Tools

  describe "chat/2" do
    test "returns parsed text response" do
      Req.Test.stub(:anthropic, fn conn ->
        assert {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)

        assert decoded["model"] == "claude-sonnet-4-6"
        assert decoded["max_tokens"] == 4096
        assert [%{"role" => "user", "content" => "Hello"}] = decoded["messages"]

        Req.Test.json(conn, %{
          "content" => [%{"type" => "text", "text" => "Hi there!"}],
          "stop_reason" => "end_turn",
          "usage" => %{"input_tokens" => 10, "output_tokens" => 5}
        })
      end)

      assert {:ok, response} =
               Backend.Anthropic.chat(
                 [%{role: "user", content: "Hello"}],
                 req_options: [plug: {Req.Test, :anthropic}]
               )

      assert response.stop_reason == "end_turn"
      assert [%{type: :text, text: "Hi there!"}] = response.content
      assert response.usage["input_tokens"] == 10
    end

    test "passes system prompt when provided" do
      Req.Test.stub(:anthropic, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)

        assert decoded["system"] == "You are a helpful assistant."

        Req.Test.json(conn, %{
          "content" => [%{"type" => "text", "text" => "OK"}],
          "stop_reason" => "end_turn",
          "usage" => %{"input_tokens" => 10, "output_tokens" => 2}
        })
      end)

      assert {:ok, _} =
               Backend.Anthropic.chat(
                 [%{role: "user", content: "Hi"}],
                 system: "You are a helpful assistant.",
                 req_options: [plug: {Req.Test, :anthropic}]
               )
    end

    test "returns error on API error response" do
      Req.Test.stub(:anthropic, fn conn ->
        conn
        |> Plug.Conn.put_status(401)
        |> Req.Test.json(%{
          "error" => %{"type" => "authentication_error", "message" => "invalid x-api-key"}
        })
      end)

      assert {:error, %{status: 401, type: "authentication_error"}} =
               Backend.Anthropic.chat(
                 [%{role: "user", content: "Hello"}],
                 req_options: [plug: {Req.Test, :anthropic}]
               )
    end

    test "parses tool_use content blocks" do
      Req.Test.stub(:anthropic, fn conn ->
        Req.Test.json(conn, %{
          "content" => [
            %{"type" => "text", "text" => "I'll check the weather."},
            %{"type" => "tool_use", "id" => "toolu_123", "name" => "get_weather", "input" => %{"location" => "London"}}
          ],
          "stop_reason" => "tool_use",
          "usage" => %{"input_tokens" => 20, "output_tokens" => 15}
        })
      end)

      assert {:ok, response} =
               Backend.Anthropic.chat(
                 [%{role: "user", content: "What's the weather?"}],
                 req_options: [plug: {Req.Test, :anthropic}]
               )

      assert response.stop_reason == "tool_use"

      assert [%{type: :text}, %{type: :tool_use, name: "get_weather", id: "toolu_123", input: %{"location" => "London"}}] =
               response.content
    end
  end

  describe "run/2" do
    test "falls back to chat when no tools provided" do
      Req.Test.stub(:anthropic, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)

        # Should not include tools in the request
        refute Map.has_key?(decoded, "tools")

        Req.Test.json(conn, %{
          "content" => [%{"type" => "text", "text" => "No tools needed."}],
          "stop_reason" => "end_turn",
          "usage" => %{"input_tokens" => 10, "output_tokens" => 5}
        })
      end)

      assert {:ok, response} =
               Backend.Anthropic.run(
                 [%{role: "user", content: "Hello"}],
                 req_options: [plug: {Req.Test, :anthropic}]
               )

      assert [%{type: :text, text: "No tools needed."}] = response.content
    end

    test "executes tool calls and feeds results back" do
      call_count = :counters.new(1, [:atomics])

      Req.Test.stub(:anthropic, fn conn ->
        :counters.add(call_count, 1, 1)
        count = :counters.get(call_count, 1)

        if count == 1 do
          Req.Test.json(conn, %{
            "content" => [
              %{"type" => "text", "text" => "Let me read that."},
              %{"type" => "tool_use", "id" => "toolu_1", "name" => "read_document", "input" => %{"document_id" => 999}}
            ],
            "stop_reason" => "tool_use",
            "usage" => %{"input_tokens" => 20, "output_tokens" => 15}
          })
        else
          # Verify the tool result was sent back
          {:ok, body, conn} = Plug.Conn.read_body(conn)
          decoded = Jason.decode!(body)
          messages = decoded["messages"]
          last_message = List.last(messages)

          assert last_message["role"] == "user"
          assert [%{"type" => "tool_result", "tool_use_id" => "toolu_1"} | _] = last_message["content"]

          Req.Test.json(conn, %{
            "content" => [%{"type" => "text", "text" => "Here's what I found."}],
            "stop_reason" => "end_turn",
            "usage" => %{"input_tokens" => 30, "output_tokens" => 10}
          })
        end
      end)

      assert {:ok, response} =
               Backend.Anthropic.run(
                 [%{role: "user", content: "Read document 999"}],
                 tools: Tools.definitions(["document_tools"]),
                 req_options: [plug: {Req.Test, :anthropic}]
               )

      assert [%{type: :text, text: "Here's what I found."}] = response.content
      assert :counters.get(call_count, 1) == 2
    end

    test "returns error when max iterations reached" do
      # Always return tool_use to force the loop to hit the limit
      Req.Test.stub(:anthropic, fn conn ->
        Req.Test.json(conn, %{
          "content" => [
            %{"type" => "tool_use", "id" => "toolu_1", "name" => "read_document", "input" => %{"document_id" => 1}}
          ],
          "stop_reason" => "tool_use",
          "usage" => %{"input_tokens" => 10, "output_tokens" => 5}
        })
      end)

      assert {:error, :max_iterations} =
               Backend.Anthropic.run(
                 [%{role: "user", content: "Loop forever"}],
                 tools: Tools.definitions(["document_tools"]),
                 req_options: [plug: {Req.Test, :anthropic}]
               )
    end
  end
end
