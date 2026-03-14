defmodule Backend.Conversations.MessageFormat do
  @moduledoc false

  import Saxy.XML

  @doc """
  Encodes a message's content and context into XML for the Claude API.

  Returns a string like:
      <message>
        <context type="document" id="42" action="viewing" title="Compliance Policy"/>
        <content>Check this for spelling mistakes</content>
      </message>

  When context is nil, the context element is omitted:
      <message>
        <content>Hello</content>
      </message>
  """
  def encode(content, context) do
    children = [context_element(context), element("content", [], content)]

    "message"
    |> element([], Enum.reject(children, &is_nil/1))
    |> Saxy.encode!()
  end

  @doc """
  Decodes an XML message string back into content and context.

  Returns `{content, context}` where context is a map or nil.
  """
  def decode(xml) do
    {:ok, result} = Saxy.SimpleForm.parse_string(xml)
    {"message", _, children} = result

    content = extract_content(children)
    context = extract_context(children)

    {content, context}
  end

  defp context_element(nil), do: nil

  defp context_element(context) do
    attrs =
      context
      |> Enum.map(fn {k, v} -> {to_string(k), to_string(v)} end)
      |> Enum.sort()

    element("context", attrs, [])
  end

  defp extract_content(children) do
    Enum.find_value(children, fn
      {"content", _, [text]} -> text
      _ -> nil
    end)
  end

  defp extract_context(children) do
    Enum.find_value(children, fn
      {"context", attrs, _} -> Map.new(attrs)
      _ -> nil
    end)
  end
end
