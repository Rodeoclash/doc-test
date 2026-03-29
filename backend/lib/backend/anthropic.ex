defmodule Backend.Anthropic do
  @moduledoc false

  alias Backend.Anthropic.Tools

  require Logger

  @api_url "https://api.anthropic.com/v1/messages"
  @api_version "2023-06-01"
  @default_model "claude-sonnet-4-6"
  @default_max_tokens 16_384
  @max_iterations 10

  @doc """
  Sends a message to the Claude API and returns the parsed response.

  ## Options

    * `:model` - Model ID (default: `"claude-sonnet-4-6"`)
    * `:max_tokens` - Maximum tokens in response (default: `4096`)
    * `:system` - System prompt string
    * `:tools` - List of tool definitions
  """
  def chat(messages, opts \\ []) do
    body =
      %{
        model: opts[:model] || @default_model,
        max_tokens: opts[:max_tokens] || @default_max_tokens,
        messages: messages
      }
      |> maybe_put(:system, opts[:system])
      |> maybe_put(:tools, opts[:tools])

    Logger.info("Anthropic request: #{Jason.encode!(body, pretty: true)}")

    case Req.post(req(opts), json: body) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        Logger.info("Anthropic response: stop_reason=#{body["stop_reason"]}")
        {:ok, parse_response(body)}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, %{status: status, type: body["error"]["type"], message: body["error"]["message"]}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Runs a conversation with tool use. Sends messages to Claude with tool definitions,
  executes any tool calls, feeds results back, and repeats until Claude is done.
  When no tools are provided, falls back to a simple chat call.

  ## Options

    * `:tools` - List of tool definitions (default: `[]`)
    * All options from `chat/2`
  """
  def run(messages, opts \\ []) do
    {tools, opts} = Keyword.pop(opts, :tools, [])

    if tools == [] do
      chat(messages, opts)
    else
      do_run(messages, tools, opts, 0)
    end
  end

  defp do_run(_messages, _tools, _opts, iteration) when iteration >= @max_iterations do
    {:error, :max_iterations}
  end

  defp do_run(messages, tools, opts, iteration) do
    case chat(messages, Keyword.put(opts, :tools, tools)) do
      {:ok, %{stop_reason: "end_turn"} = response} ->
        {:ok, response}

      {:ok, %{stop_reason: "tool_use", content: content}} ->
        tool_results = execute_tool_calls(content)
        assistant_message = %{role: "assistant", content: format_content_for_api(content)}
        tool_message = %{role: "user", content: tool_results}
        updated_messages = messages ++ [assistant_message, tool_message]
        do_run(updated_messages, tools, opts, iteration + 1)

      {:ok, %{stop_reason: "max_tokens"}} ->
        {:error, :max_tokens}

      {:error, _} = error ->
        error
    end
  end

  defp execute_tool_calls(content) do
    content
    |> Enum.filter(&(&1.type == :tool_use))
    |> Enum.map(fn %{id: id, name: name, input: input} ->
      Logger.info("Tool call: #{name} with input: #{inspect(input)}")

      result =
        case Tools.execute(name, input) do
          {:ok, data} ->
            Logger.info("Tool result: #{name} succeeded")
            Jason.encode!(data)

          {:error, reason} ->
            Logger.info("Tool result: #{name} failed: #{inspect(reason)}")
            "Error: #{inspect(reason)}"
        end

      %{type: "tool_result", tool_use_id: id, content: result}
    end)
  end

  defp format_content_for_api(content) do
    Enum.map(content, fn
      %{type: :text, text: text} -> %{type: "text", text: text}
      %{type: :tool_use, id: id, name: name, input: input} -> %{type: "tool_use", id: id, name: name, input: input}
    end)
  end

  defp parse_response(body) do
    %{
      content: parse_content(body["content"]),
      stop_reason: body["stop_reason"],
      usage: body["usage"]
    }
  end

  defp parse_content(blocks) do
    Enum.map(blocks, fn
      %{"type" => "text", "text" => text} ->
        %{type: :text, text: text}

      %{"type" => "tool_use", "id" => id, "name" => name, "input" => input} ->
        %{type: :tool_use, id: id, name: name, input: input}
    end)
  end

  defp req(opts) do
    api_key = Application.fetch_env!(:backend, :anthropic_api_key)

    [
      url: @api_url,
      headers: [
        {"x-api-key", api_key},
        {"anthropic-version", @api_version}
      ],
      receive_timeout: 45_000
    ]
    |> Keyword.merge(Application.get_env(:backend, :anthropic_req_options, []))
    |> Keyword.merge(opts[:req_options] || [])
    |> Req.new()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
