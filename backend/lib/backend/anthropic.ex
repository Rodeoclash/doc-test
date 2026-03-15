defmodule Backend.Anthropic do
  @moduledoc false

  @api_url "https://api.anthropic.com/v1/messages"
  @api_version "2023-06-01"
  @default_model "claude-sonnet-4-6"
  @default_max_tokens 4096

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

    case Req.post(req(opts), json: body) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, parse_response(body)}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, %{status: status, type: body["error"]["type"], message: body["error"]["message"]}}

      {:error, reason} ->
        {:error, reason}
    end
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
      ]
    ]
    |> Keyword.merge(Application.get_env(:backend, :anthropic_req_options, []))
    |> Keyword.merge(opts[:req_options] || [])
    |> Req.new()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
