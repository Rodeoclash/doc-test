defmodule Backend.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: Backend.Repo

  alias Backend.Documents.Document
  alias Backend.Organisations.Organisation
  def organisation_factory do
    %Organisation{
      name: sequence(:name, &"Organisation #{&1}")
    }
  end

  def document_factory do
    %Document{
      name: sequence(:name, &"Document #{&1}"),
      organisation: build(:organisation)
    }
  end
end
