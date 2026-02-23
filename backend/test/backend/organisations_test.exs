defmodule Backend.OrganisationsTest do
  use Backend.DataCase

  alias Backend.Organisations

  import Backend.OrganisationsFixtures

  describe "get/1" do
    test "returns the organisation for a valid id" do
      organisation = organisation_fixture()
      assert Organisations.get(organisation.id) == organisation
    end

    test "returns nil for a non-existent id" do
      assert Organisations.get(0) == nil
    end
  end
end
