defmodule Backend.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: Backend.Repo

  alias Backend.Accounts.User
  alias Backend.Conversations.Conversation
  alias Backend.Conversations.Message
  alias Backend.Documents.Document
  alias Backend.Documents.DocumentVersion
  alias Backend.Organisations.Organisation
  alias Backend.Organisations.OrganisationUser

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
      type: :human
    }
  end

  def agent_factory do
    %User{
      email: sequence(:email, &"agent#{&1}@system.local"),
      type: :agent
    }
  end

  def document_version_factory do
    %DocumentVersion{
      document: build(:document),
      yjs_state: <<0>>,
      major_version: 1,
      minor_version: 0,
      published_at: DateTime.utc_now(:second)
    }
  end

  def conversation_factory do
    %Conversation{
      organisation: build(:organisation),
      user: build(:user)
    }
  end

  def message_factory do
    %Message{
      role: :user,
      content: "Hello",
      conversation: build(:conversation)
    }
  end

  def organisation_user_factory do
    %OrganisationUser{
      user: build(:user),
      organisation: build(:organisation)
    }
  end
end
