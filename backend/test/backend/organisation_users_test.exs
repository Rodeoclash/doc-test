defmodule Backend.OrganisationUsersTest do
  use Backend.DataCase

  import Backend.Factory

  alias Backend.OrganisationUsers

  describe "get/1" do
    test "returns the organisation user with preloaded organisation and user" do
      org_user = insert(:organisation_user)

      result = OrganisationUsers.get(org_user.id)

      assert result.id == org_user.id
      assert result.organisation.id == org_user.organisation_id
      assert result.user.id == org_user.user_id
    end

    test "returns nil for a non-existent id" do
      assert OrganisationUsers.get(0) == nil
    end
  end

  describe "get_by_organisation_and_user/2" do
    test "returns the organisation user with preloaded organisation and user" do
      org_user = insert(:organisation_user)

      result = OrganisationUsers.get_by_organisation_and_user(org_user.organisation_id, org_user.user_id)

      assert result.id == org_user.id
      assert result.organisation.id == org_user.organisation_id
      assert result.user.id == org_user.user_id
    end

    test "returns nil when the membership does not exist" do
      org = insert(:organisation)
      user = insert(:user)

      assert OrganisationUsers.get_by_organisation_and_user(org.id, user.id) == nil
    end
  end
end
