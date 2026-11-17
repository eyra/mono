defmodule MicaSaas.Systems.Org.PublicTest do
  use Mica.DataCase

  alias Mica.Factories
  alias Systems.Org
  alias Systems.Org.Public

  describe "owner management" do
    alias Systems.NextAction

    test "assign_owner/2 creates AddDomainMembers NextAction when domain-matched users exist" do
      domain = "assign-owner-match.test"

      org =
        Factories.insert!(:org_node, %{
          identifier: ["assign_owner_match_org"],
          domains: [domain]
        })

      _candidate = Factories.insert!(:member, %{email: "candidate@#{domain}"})
      owner = Factories.insert!(:member)

      :ok = Public.assign_owner(org, owner)

      next_actions =
        NextAction.Public.list_next_actions_by_type(owner, Org.NextActions.AddDomainMembers)

      assert next_actions != []
    end

    test "revoke_owner/2 clears the AddDomainMembers NextAction for the revoked owner" do
      domain = "revoke-clear.test"

      org =
        Factories.insert!(:org_node, %{
          identifier: ["revoke_clear_org"],
          domains: [domain]
        })

      _candidate = Factories.insert!(:member, %{email: "candidate@#{domain}"})
      owner = Factories.insert!(:member)

      :ok = Public.assign_owner(org, owner)

      assert [_ | _] =
               NextAction.Public.list_next_actions_by_type(
                 owner,
                 Org.NextActions.AddDomainMembers
               )

      :ok = Public.revoke_owner(org, owner)

      assert Enum.empty?(
               NextAction.Public.list_next_actions_by_type(
                 owner,
                 Org.NextActions.AddDomainMembers
               )
             )
    end

    test "revoke_owner/2 leaves other owners' NextActions intact" do
      domain = "revoke-isolation.test"

      org =
        Factories.insert!(:org_node, %{
          identifier: ["revoke_isolation_org"],
          domains: [domain]
        })

      _candidate = Factories.insert!(:member, %{email: "candidate@#{domain}"})
      owner1 = Factories.insert!(:member)
      owner2 = Factories.insert!(:member)

      :ok = Public.assign_owner(org, owner1)
      :ok = Public.assign_owner(org, owner2)

      assert [_ | _] =
               NextAction.Public.list_next_actions_by_type(
                 owner1,
                 Org.NextActions.AddDomainMembers
               )

      assert [_ | _] =
               NextAction.Public.list_next_actions_by_type(
                 owner2,
                 Org.NextActions.AddDomainMembers
               )

      :ok = Public.revoke_owner(org, owner1)

      assert Enum.empty?(
               NextAction.Public.list_next_actions_by_type(
                 owner1,
                 Org.NextActions.AddDomainMembers
               )
             )

      assert [_ | _] =
               NextAction.Public.list_next_actions_by_type(
                 owner2,
                 Org.NextActions.AddDomainMembers
               )
    end
  end

  describe "sync_next_actions_for_new_user/1" do
    alias Systems.NextAction

    test "creates NextAction for org owner when new user's domain matches" do
      # Create an org with a unique domain
      org =
        Factories.insert!(:org_node, %{
          identifier: ["sync_test_org"],
          domains: ["sync-test.example"]
        })

      # Create an owner for the org
      owner = Factories.insert!(:member)
      Mica.Authorization.assign_role(owner, org, :owner)

      # Create a new user with matching domain
      new_user = Factories.insert!(:member, %{email: "newuser@sync-test.example"})

      # Sync next actions for the new user
      Public.sync_next_actions_for_new_user(new_user)

      # Verify the owner has a NextAction of the correct type
      next_actions =
        NextAction.Public.list_next_actions_by_type(owner, Org.NextActions.AddDomainMembers)

      assert next_actions != []
    end

    test "creates NextAction for multiple org owners" do
      # Create an org with a unique domain
      org =
        Factories.insert!(:org_node, %{
          identifier: ["multi_owner_org"],
          domains: ["multi-owner.test"]
        })

      # Create two owners for the org
      owner1 = Factories.insert!(:member)
      owner2 = Factories.insert!(:member)
      Mica.Authorization.assign_role(owner1, org, :owner)
      Mica.Authorization.assign_role(owner2, org, :owner)

      # Create a new user with matching domain
      new_user = Factories.insert!(:member, %{email: "newuser@multi-owner.test"})

      # Sync next actions for the new user
      Public.sync_next_actions_for_new_user(new_user)

      # Verify both owners have a NextAction
      next_actions1 =
        NextAction.Public.list_next_actions_by_type(owner1, Org.NextActions.AddDomainMembers)

      next_actions2 =
        NextAction.Public.list_next_actions_by_type(owner2, Org.NextActions.AddDomainMembers)

      assert next_actions1 != []
      assert next_actions2 != []
    end
  end
end
