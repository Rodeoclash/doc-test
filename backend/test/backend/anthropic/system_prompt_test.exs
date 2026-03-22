defmodule Backend.Anthropic.SystemPromptTest do
  use ExUnit.Case, async: true

  alias Backend.Anthropic.SystemPrompt

  describe "build/1" do
    test "includes organisation name" do
      prompt = SystemPrompt.build(organisation_name: "Acme Corp")

      assert prompt =~ "You are an AI assistant for Acme Corp."
    end

    test "includes markdown instruction" do
      prompt = SystemPrompt.build(organisation_name: "Acme Corp")

      assert prompt =~ "Respond using Markdown formatting where appropriate."
    end

    test "includes tool instructions when capabilities are present" do
      prompt = SystemPrompt.build(organisation_name: "Acme Corp", capabilities: ["document_tools"])

      assert prompt =~ "You have tools available."
    end

    test "omits tool instructions when no capabilities" do
      prompt = SystemPrompt.build(organisation_name: "Acme Corp", capabilities: [])

      refute prompt =~ "You have tools available."
    end

    test "includes node descriptions for document_tools capability" do
      prompt = SystemPrompt.build(organisation_name: "Acme Corp", capabilities: ["document_tools"])

      assert prompt =~ "Document Node Types"
    end

    test "omits node descriptions without document_tools capability" do
      prompt = SystemPrompt.build(organisation_name: "Acme Corp", capabilities: [])

      refute prompt =~ "Document Node Types"
    end

    test "raises when organisation_name is missing" do
      assert_raise KeyError, fn ->
        SystemPrompt.build([])
      end
    end
  end
end
