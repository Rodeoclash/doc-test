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

    test "raises when organisation_name is missing" do
      assert_raise KeyError, fn ->
        SystemPrompt.build([])
      end
    end
  end
end
