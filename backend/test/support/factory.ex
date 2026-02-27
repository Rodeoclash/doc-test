defmodule Backend.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: Backend.Repo

  alias Backend.Documents.Document
  alias Backend.Organisations.Organisation
  alias Backend.SectionTags.SectionTag

  def organisation_factory do
    %Organisation{
      name: sequence(:name, &"Organisation #{&1}")
    }
  end

  def section_tag_factory do
    %SectionTag{
      name: sequence(:name, &"Section #{&1}"),
      description: "A test section tag description",
      organisation: build(:organisation)
    }
  end

  def document_factory do
    %Document{
      name: sequence(:name, &"Document #{&1}"),
      content: %{},
      organisation: build(:organisation)
    }
  end
end
