defmodule Backend.OrganisationsTest do
  use Backend.DataCase

  alias Backend.Organisations

  describe "organisations" do
    alias Backend.Organisations.Organisation

    import Backend.OrganisationsFixtures

    @invalid_attrs %{name: nil}

    test "list_organisations/0 returns all organisations" do
      organisation = organisation_fixture()
      assert Organisations.list_organisations() == [organisation]
    end

    test "get_organisation!/1 returns the organisation with given id" do
      organisation = organisation_fixture()
      assert Organisations.get_organisation!(organisation.id) == organisation
    end

    test "create_organisation/1 with valid data creates a organisation" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Organisation{} = organisation} = Organisations.create_organisation(valid_attrs)
      assert organisation.name == "some name"
    end

    test "create_organisation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Organisations.create_organisation(@invalid_attrs)
    end

    test "update_organisation/2 with valid data updates the organisation" do
      organisation = organisation_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Organisation{} = organisation} = Organisations.update_organisation(organisation, update_attrs)
      assert organisation.name == "some updated name"
    end

    test "update_organisation/2 with invalid data returns error changeset" do
      organisation = organisation_fixture()
      assert {:error, %Ecto.Changeset{}} = Organisations.update_organisation(organisation, @invalid_attrs)
      assert organisation == Organisations.get_organisation!(organisation.id)
    end

    test "delete_organisation/1 deletes the organisation" do
      organisation = organisation_fixture()
      assert {:ok, %Organisation{}} = Organisations.delete_organisation(organisation)
      assert_raise Ecto.NoResultsError, fn -> Organisations.get_organisation!(organisation.id) end
    end

    test "change_organisation/1 returns a organisation changeset" do
      organisation = organisation_fixture()
      assert %Ecto.Changeset{} = Organisations.change_organisation(organisation)
    end
  end

  describe "section_tags" do
    alias Backend.Organisations.SectionTag

    import Backend.OrganisationsFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_section_tags/0 returns all section_tags" do
      section_tag = section_tag_fixture()
      assert Organisations.list_section_tags() == [section_tag]
    end

    test "get_section_tag!/1 returns the section_tag with given id" do
      section_tag = section_tag_fixture()
      assert Organisations.get_section_tag!(section_tag.id) == section_tag
    end

    test "create_section_tag/1 with valid data creates a section_tag" do
      valid_attrs = %{name: "some name", description: "some description"}

      assert {:ok, %SectionTag{} = section_tag} = Organisations.create_section_tag(valid_attrs)
      assert section_tag.name == "some name"
      assert section_tag.description == "some description"
    end

    test "create_section_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Organisations.create_section_tag(@invalid_attrs)
    end

    test "update_section_tag/2 with valid data updates the section_tag" do
      section_tag = section_tag_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %SectionTag{} = section_tag} = Organisations.update_section_tag(section_tag, update_attrs)
      assert section_tag.name == "some updated name"
      assert section_tag.description == "some updated description"
    end

    test "update_section_tag/2 with invalid data returns error changeset" do
      section_tag = section_tag_fixture()
      assert {:error, %Ecto.Changeset{}} = Organisations.update_section_tag(section_tag, @invalid_attrs)
      assert section_tag == Organisations.get_section_tag!(section_tag.id)
    end

    test "delete_section_tag/1 deletes the section_tag" do
      section_tag = section_tag_fixture()
      assert {:ok, %SectionTag{}} = Organisations.delete_section_tag(section_tag)
      assert_raise Ecto.NoResultsError, fn -> Organisations.get_section_tag!(section_tag.id) end
    end

    test "change_section_tag/1 returns a section_tag changeset" do
      section_tag = section_tag_fixture()
      assert %Ecto.Changeset{} = Organisations.change_section_tag(section_tag)
    end
  end
end
