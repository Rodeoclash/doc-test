defmodule Backend.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: Backend.Repo

  alias Backend.Accounts.User
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

  def user_factory do
    %User{
      email: sequence(:email, &"user#{&1}@example.com"),
      type: :human,
      organisation: build(:organisation)
    }
  end

  def agent_factory do
    %User{
      email: sequence(:email, &"agent#{&1}@system.local"),
      type: :agent,
      organisation: build(:organisation)
    }
  end
end
