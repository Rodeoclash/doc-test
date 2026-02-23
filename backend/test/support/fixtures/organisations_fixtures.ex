defmodule Backend.OrganisationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Backend.Organisations` context.
  """

  @doc """
  Generate a organisation.
  """
  def organisation_fixture(attrs \\ %{}) do
    {:ok, organisation} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Backend.Organisations.create_organisation()

    organisation
  end

  @doc """
  Generate a section_tag.
  """
  def section_tag_fixture(attrs \\ %{}) do
    {:ok, section_tag} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name"
      })
      |> Backend.Organisations.create_section_tag()

    section_tag
  end

  @doc """
  Generate a document.
  """
  def document_fixture(attrs \\ %{}) do
    {:ok, document} =
      attrs
      |> Enum.into(%{
        content: %{},
        name: "some name"
      })
      |> Backend.Organisations.create_document()

    document
  end
end
