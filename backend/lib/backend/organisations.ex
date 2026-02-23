defmodule Backend.Organisations do
  @moduledoc """
  The Organisations context.
  """

  import Ecto.Query, warn: false
  alias Backend.Repo

  alias Backend.Organisations.Organisation

  @doc """
  Returns the list of organisations.

  ## Examples

      iex> list_organisations()
      [%Organisation{}, ...]

  """
  def list_organisations do
    Repo.all(Organisation)
  end

  @doc """
  Gets a single organisation.

  Raises `Ecto.NoResultsError` if the Organisation does not exist.

  ## Examples

      iex> get_organisation!(123)
      %Organisation{}

      iex> get_organisation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_organisation!(id), do: Repo.get!(Organisation, id)

  @doc """
  Creates a organisation.

  ## Examples

      iex> create_organisation(%{field: value})
      {:ok, %Organisation{}}

      iex> create_organisation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_organisation(attrs) do
    %Organisation{}
    |> Organisation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a organisation.

  ## Examples

      iex> update_organisation(organisation, %{field: new_value})
      {:ok, %Organisation{}}

      iex> update_organisation(organisation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_organisation(%Organisation{} = organisation, attrs) do
    organisation
    |> Organisation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a organisation.

  ## Examples

      iex> delete_organisation(organisation)
      {:ok, %Organisation{}}

      iex> delete_organisation(organisation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_organisation(%Organisation{} = organisation) do
    Repo.delete(organisation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking organisation changes.

  ## Examples

      iex> change_organisation(organisation)
      %Ecto.Changeset{data: %Organisation{}}

  """
  def change_organisation(%Organisation{} = organisation, attrs \\ %{}) do
    Organisation.changeset(organisation, attrs)
  end

  alias Backend.Organisations.SectionTag

  @doc """
  Returns the list of section_tags.

  ## Examples

      iex> list_section_tags()
      [%SectionTag{}, ...]

  """
  def list_section_tags do
    Repo.all(SectionTag)
  end

  @doc """
  Gets a single section_tag.

  Raises `Ecto.NoResultsError` if the Section tag does not exist.

  ## Examples

      iex> get_section_tag!(123)
      %SectionTag{}

      iex> get_section_tag!(456)
      ** (Ecto.NoResultsError)

  """
  def get_section_tag!(id), do: Repo.get!(SectionTag, id)

  @doc """
  Creates a section_tag.

  ## Examples

      iex> create_section_tag(%{field: value})
      {:ok, %SectionTag{}}

      iex> create_section_tag(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_section_tag(attrs) do
    %SectionTag{}
    |> SectionTag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a section_tag.

  ## Examples

      iex> update_section_tag(section_tag, %{field: new_value})
      {:ok, %SectionTag{}}

      iex> update_section_tag(section_tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_section_tag(%SectionTag{} = section_tag, attrs) do
    section_tag
    |> SectionTag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a section_tag.

  ## Examples

      iex> delete_section_tag(section_tag)
      {:ok, %SectionTag{}}

      iex> delete_section_tag(section_tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_section_tag(%SectionTag{} = section_tag) do
    Repo.delete(section_tag)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking section_tag changes.

  ## Examples

      iex> change_section_tag(section_tag)
      %Ecto.Changeset{data: %SectionTag{}}

  """
  def change_section_tag(%SectionTag{} = section_tag, attrs \\ %{}) do
    SectionTag.changeset(section_tag, attrs)
  end
end
