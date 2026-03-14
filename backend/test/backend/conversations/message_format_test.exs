defmodule Backend.Conversations.MessageFormatTest do
  use ExUnit.Case, async: true

  alias Backend.Conversations.MessageFormat

  describe "encode/2" do
    test "encodes content with context" do
      xml =
        MessageFormat.encode("Check this for spelling mistakes", %{
          "type" => "document",
          "id" => "42",
          "action" => "viewing",
          "title" => "Compliance Policy"
        })

      assert xml =~ "<message>"
      assert xml =~ "<content>Check this for spelling mistakes</content>"
      assert xml =~ ~s(action="viewing")
      assert xml =~ ~s(id="42")
      assert xml =~ ~s(title="Compliance Policy")
      assert xml =~ ~s(type="document")
    end

    test "encodes content without context" do
      xml = MessageFormat.encode("Hello", nil)

      assert xml =~ "<content>Hello</content>"
      refute xml =~ "<context"
    end
  end

  describe "decode/1" do
    test "decodes XML with context" do
      xml =
        MessageFormat.encode("Rewrite the intro", %{
          "type" => "document",
          "id" => "42",
          "action" => "editing",
          "title" => "Compliance Policy"
        })

      {content, context} = MessageFormat.decode(xml)

      assert content == "Rewrite the intro"
      assert context == %{"type" => "document", "id" => "42", "action" => "editing", "title" => "Compliance Policy"}
    end

    test "decodes XML without context" do
      xml = MessageFormat.encode("Hello", nil)

      {content, context} = MessageFormat.decode(xml)

      assert content == "Hello"
      assert context == nil
    end
  end

  describe "round-trip" do
    test "encode then decode preserves data" do
      original_content = "Check this document"
      original_context = %{"type" => "document", "id" => "42", "action" => "viewing", "title" => "My Doc"}

      xml = MessageFormat.encode(original_content, original_context)
      {content, context} = MessageFormat.decode(xml)

      assert content == original_content
      assert context == original_context
    end
  end
end
