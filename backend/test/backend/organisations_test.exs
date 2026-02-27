defmodule Backend.OrganisationsTest do
  use Backend.DataCase

  import Backend.Factory

  alias Backend.Organisations

  describe "get/1" do
    test "returns the organisation for a valid id" do
      organisation = insert(:organisation)
      assert Organisations.get(organisation.id) == organisation
    end

    test "returns nil for a non-existent id" do
      assert Organisations.get(0) == nil
    end
  end
end
