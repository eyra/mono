defmodule Systems.Org.PublicTest do
  use Core.DataCase

  alias Core.Factories
  alias Systems.Org
  alias Systems.Org.Public

  describe "organisation" do
    test "create minimal node" do
      assert %{identifier: ["uva"]} = Public.create_node!(%{identifier: ["uva"]})
    end

    test "create existing node fails" do
      Public.create_node!(%{identifier: ["uva"]})

      assert_raise Ecto.InvalidChangesetError, fn ->
        Public.create_node!(%{identifier: ["uva"]})
      end
    end

    test "get_node/2 returns node by identifier" do
      org = Factories.insert!(:org_node, %{identifier: ["test_get"]})

      result = Public.get_node(["test_get"])
      assert result.id == org.id
    end

    test "get_node/2 returns nil for non-existent identifier" do
      assert Public.get_node(["non_existent"]) == nil
    end

    test "get_link/3 returns link between two nodes" do
      node1 = Public.create_node!(%{identifier: ["link_from"]})
      node2 = Public.create_node!(%{identifier: ["link_to"]})
      Public.create_link!(node1, node2)

      link = Public.get_link(node1, node2)

      assert link.from_id == node1.id
      assert link.to_id == node2.id
    end

    test "get_link/3 returns nil when no link exists" do
      node1 = Public.create_node!(%{identifier: ["no_link_1"]})
      node2 = Public.create_node!(%{identifier: ["no_link_2"]})

      assert Public.get_link(node1, node2) == nil
    end

    test "link two nodes unidirectional" do
      %{id: node1_id} = node1 = Public.create_node!(%{identifier: ["uva"]})
      %{id: node2_id} = node2 = Public.create_node!(%{identifier: ["sbe"]})

      assert %{
               from: %{id: ^node1_id},
               to: %{id: ^node2_id}
             } = Public.create_link!(node1, node2)

      assert %{
               links: [
                 %{
                   id: ^node2_id
                 }
               ],
               reverse_links: []
             } = Public.get_node!(node1_id, [:links, :reverse_links])

      assert %{
               links: [],
               reverse_links: [
                 %{
                   id: ^node1_id
                 }
               ]
             } = Public.get_node!(node2_id, [:links, :reverse_links])
    end

    test "link two nodes bidirectional" do
      %{id: node1_id} = node1 = Public.create_node!(%{identifier: ["uva"]})
      %{id: node2_id} = node2 = Public.create_node!(%{identifier: ["sbe"]})

      Public.create_link!(node1, node2)
      Public.create_link!(node2, node1)

      assert %{
               links: [
                 %{
                   id: ^node2_id
                 }
               ],
               reverse_links: [
                 %{
                   id: ^node2_id
                 }
               ]
             } = Public.get_node!(node1_id, [:links, :reverse_links])

      assert %{
               links: [
                 %{
                   id: ^node1_id
                 }
               ],
               reverse_links: [
                 %{
                   id: ^node1_id
                 }
               ]
             } = Public.get_node!(node2_id, [:links, :reverse_links])
    end
  end

  describe "user association management" do
    test "add_user/2 with identifier adds user to org" do
      org = Factories.insert!(:org_node, %{identifier: ["add_user_org"]})
      user = Factories.insert!(:member)

      Public.add_user(["add_user_org"], user)

      org_with_users = Public.get_node!(org.id, [:users])
      assert length(org_with_users.users) == 1
      assert hd(org_with_users.users).id == user.id
    end

    test "add_user/2 with node adds user to org" do
      org = Factories.insert!(:org_node, %{identifier: ["add_user_node"]})
      user = Factories.insert!(:member)

      Public.add_user(org, user)

      org_with_users = Public.get_node!(org.id, [:users])
      assert length(org_with_users.users) == 1
      assert hd(org_with_users.users).id == user.id
    end

    test "add_user/2 handles duplicate gracefully" do
      org = Factories.insert!(:org_node, %{identifier: ["dup_user_org"]})
      user = Factories.insert!(:member)

      Public.add_user(org, user)
      Public.add_user(org, user)

      org_with_users = Public.get_node!(org.id, [:users])
      assert length(org_with_users.users) == 1
    end

    test "delete_user/2 with identifier removes user from org" do
      org = Factories.insert!(:org_node, %{identifier: ["del_user_org"]})
      user = Factories.insert!(:member)
      Public.add_user(org, user)

      Public.delete_user(["del_user_org"], user)

      org_with_users = Public.get_node!(org.id, [:users])
      assert Enum.empty?(org_with_users.users)
    end

    test "delete_user/2 with node removes user from org" do
      org = Factories.insert!(:org_node, %{identifier: ["del_node_org"]})
      user = Factories.insert!(:member)
      Public.add_user(org, user)

      Public.delete_user(org, user)

      org_with_users = Public.get_node!(org.id, [:users])
      assert Enum.empty?(org_with_users.users)
    end
  end

  describe "node listing" do
    test "list_nodes/1 returns all non-archived nodes" do
      org1 = Factories.insert!(:org_node, %{identifier: ["list_org1"]})
      org2 = Factories.insert!(:org_node, %{identifier: ["list_org2"]})

      archived_org =
        Factories.insert!(:org_node, %{
          identifier: ["list_archived"],
          archived_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      nodes = Public.list_nodes([])
      node_ids = Enum.map(nodes, & &1.id)

      assert org1.id in node_ids
      assert org2.id in node_ids
      refute archived_org.id in node_ids
    end

    test "list_nodes/2 with user returns orgs the user belongs to" do
      user = Factories.insert!(:member)
      org1 = Factories.insert!(:org_node, %{identifier: ["user_org1"]})
      org2 = Factories.insert!(:org_node, %{identifier: ["user_org2"]})
      _org3 = Factories.insert!(:org_node, %{identifier: ["other_org"]})

      Public.add_user(org1, user)
      Public.add_user(org2, user)

      nodes = Public.list_nodes(user, [])
      node_ids = Enum.map(nodes, & &1.id)

      assert length(nodes) == 2
      assert org1.id in node_ids
      assert org2.id in node_ids
    end

    test "list_nodes/2 with identifier_template returns matching nodes" do
      _org1 = Factories.insert!(:org_node, %{identifier: ["parent", "child1"]})
      _org2 = Factories.insert!(:org_node, %{identifier: ["parent", "child2"]})
      _other = Factories.insert!(:org_node, %{identifier: ["other"]})

      nodes = Public.list_nodes(["parent"], [])

      assert length(nodes) == 2
      identifiers = Enum.map(nodes, & &1.identifier)
      assert ["parent", "child1"] in identifiers
      assert ["parent", "child2"] in identifiers
    end

    test "list_all_nodes/1 includes archived nodes" do
      org = Factories.insert!(:org_node, %{identifier: ["all_org"]})

      archived_org =
        Factories.insert!(:org_node, %{
          identifier: ["all_archived"],
          archived_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      nodes = Public.list_all_nodes([])
      node_ids = Enum.map(nodes, & &1.id)

      assert org.id in node_ids
      assert archived_org.id in node_ids
    end

    test "list_archived_nodes/1 returns only archived nodes" do
      _org = Factories.insert!(:org_node, %{identifier: ["active_org"]})

      archived_org =
        Factories.insert!(:org_node, %{
          identifier: ["archived_only"],
          archived_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      nodes = Public.list_archived_nodes([])
      node_ids = Enum.map(nodes, & &1.id)

      refute _org.id in node_ids
      assert archived_org.id in node_ids
    end
  end

  describe "archive management" do
    test "archive/1 sets archived_at timestamp" do
      org = Factories.insert!(:org_node, %{identifier: ["to_archive"]})

      {:ok, archived_org} = Public.archive(org)

      assert archived_org.archived_at != nil
    end

    test "archive/1 removes org from list_nodes" do
      org = Factories.insert!(:org_node, %{identifier: ["archive_list_test"]})

      nodes_before = Public.list_nodes([])
      assert org.id in Enum.map(nodes_before, & &1.id)

      {:ok, _} = Public.archive(org)

      nodes_after = Public.list_nodes([])
      refute org.id in Enum.map(nodes_after, & &1.id)
    end

    test "restore/1 clears archived_at timestamp" do
      org =
        Factories.insert!(:org_node, %{
          identifier: ["to_restore"],
          archived_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      {:ok, restored_org} = Public.restore(org)

      assert restored_org.archived_at == nil
    end

    test "restore/1 adds org back to list_nodes" do
      org =
        Factories.insert!(:org_node, %{
          identifier: ["restore_list_test"],
          archived_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      nodes_before = Public.list_nodes([])
      refute org.id in Enum.map(nodes_before, & &1.id)

      {:ok, _} = Public.restore(org)

      nodes_after = Public.list_nodes([])
      assert org.id in Enum.map(nodes_after, & &1.id)
    end
  end

  describe "owner management" do
    test "list_owners returns users with :owner role" do
      user = Factories.insert!(:member)
      org = Factories.insert!(:org_node, %{identifier: ["test_uni"]})
      Core.Authorization.assign_role(user, org, :owner)

      owners = Public.list_owners(org)

      assert length(owners) == 1
      assert hd(owners).id == user.id
    end

    test "list_owners returns empty list when org has no auth_node" do
      org = %Org.NodeModel{id: 999, auth_node_id: nil}
      assert Public.list_owners(org) == []
    end

    test "list_orgs returns organisations where user is owner" do
      user = Factories.insert!(:member)
      org1 = Factories.insert!(:org_node, %{identifier: ["org1"]})
      org2 = Factories.insert!(:org_node, %{identifier: ["org2"]})
      _org3 = Factories.insert!(:org_node, %{identifier: ["org3"]})

      Core.Authorization.assign_role(user, org1, :owner)
      Core.Authorization.assign_role(user, org2, :owner)

      orgs = Public.list_orgs(user)

      assert length(orgs) == 2
      org_ids = Enum.map(orgs, & &1.id)
      assert org1.id in org_ids
      assert org2.id in org_ids
    end

    test "list_orgs returns empty list when user owns no organisations" do
      user = Factories.insert!(:member)
      _org = Factories.insert!(:org_node, %{identifier: ["some_org"]})

      assert Public.list_orgs(user) == []
    end

    test "assign_owner/2 assigns :owner role to user" do
      user = Factories.insert!(:member)
      org = Factories.insert!(:org_node, %{identifier: ["assign_owner_org"]})

      :ok = Public.assign_owner(org, user)

      owners = Public.list_owners(org)
      assert length(owners) == 1
      assert hd(owners).id == user.id
    end

    test "revoke_owner/2 removes :owner role from user" do
      user = Factories.insert!(:member)
      org = Factories.insert!(:org_node, %{identifier: ["revoke_owner_org"]})
      Core.Authorization.assign_role(user, org, :owner)

      assert length(Public.list_owners(org)) == 1

      Public.revoke_owner(org, user)

      assert Enum.empty?(Public.list_owners(org))
    end

    test "owns_any?/1 returns true when user owns at least one org" do
      user = Factories.insert!(:member)
      org = Factories.insert!(:org_node, %{identifier: ["owns_any_org"]})
      Core.Authorization.assign_role(user, org, :owner)

      assert Public.owns_any?(user)
    end

    test "owns_any?/1 returns false when user owns no orgs" do
      user = Factories.insert!(:member)
      _org = Factories.insert!(:org_node, %{identifier: ["not_owned_org"]})

      refute Public.owns_any?(user)
    end

    test "owns_any?/1 returns false for nil" do
      refute Public.owns_any?(nil)
    end
  end

  describe "member management" do
    test "add_member assigns :member role to user" do
      user = Factories.insert!(:member)
      org = Factories.insert!(:org_node, %{identifier: ["test_org"]})

      assert :ok = Public.add_member(org, user)
      assert Public.member?(org, user)
    end

    test "list_members returns users with :member role" do
      user1 = Factories.insert!(:member)
      user2 = Factories.insert!(:member)
      org = Factories.insert!(:org_node, %{identifier: ["members_org"]})

      Public.add_member(org, user1)
      Public.add_member(org, user2)

      members = Public.list_members(org)

      assert length(members) == 2
      member_ids = Enum.map(members, & &1.id)
      assert user1.id in member_ids
      assert user2.id in member_ids
    end

    test "list_members returns empty list when org has no auth_node" do
      org = %Org.NodeModel{id: 999, auth_node_id: nil}
      assert Public.list_members(org) == []
    end

    test "remove_member revokes :member role" do
      user = Factories.insert!(:member)
      org = Factories.insert!(:org_node, %{identifier: ["remove_org"]})

      Public.add_member(org, user)
      assert Public.member?(org, user)

      Public.remove_member(org, user)
      refute Public.member?(org, user)
    end

    test "member? returns true when user has :member role" do
      user = Factories.insert!(:member)
      org = Factories.insert!(:org_node, %{identifier: ["member_check"]})

      refute Public.member?(org, user)

      Public.add_member(org, user)
      assert Public.member?(org, user)
    end
  end

  describe "domain matching" do
    test "find_domain_matched_users finds users by email domain" do
      user1 = Factories.insert!(:member, %{email: "test@vu.nl"})
      user2 = Factories.insert!(:member, %{email: "test@students.vu.nl"})
      _user3 = Factories.insert!(:member, %{email: "test@other.com"})

      matched = Public.find_domain_matched_users(["vu.nl", "students.vu.nl"], [])

      matched_ids = Enum.map(matched, & &1.id)
      assert user1.id in matched_ids
      assert user2.id in matched_ids
      assert length(matched) == 2
    end

    test "find_domain_matched_users excludes current members" do
      existing_member = Factories.insert!(:member, %{email: "existing@vu.nl"})
      new_user = Factories.insert!(:member, %{email: "new@vu.nl"})

      matched = Public.find_domain_matched_users(["vu.nl"], [existing_member])

      assert length(matched) == 1
      assert hd(matched).id == new_user.id
    end

    test "find_domain_matched_users returns empty for nil domains" do
      assert Public.find_domain_matched_users(nil, []) == []
    end

    test "find_domain_matched_users returns empty for empty domains" do
      assert Public.find_domain_matched_users([], []) == []
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
      Core.Authorization.assign_role(owner, org, :owner)

      # Create a new user with matching domain
      new_user = Factories.insert!(:member, %{email: "newuser@sync-test.example"})

      # Sync next actions for the new user
      Public.sync_next_actions_for_new_user(new_user)

      # Verify the owner has a NextAction of the correct type
      next_actions =
        NextAction.Public.list_next_actions_by_type(owner, Org.NextActions.AddDomainMembers)

      assert length(next_actions) >= 1
    end

    test "does not create NextAction when new user's domain doesn't match" do
      # Create an org with a unique domain
      org =
        Factories.insert!(:org_node, %{
          identifier: ["nomatch_org"],
          domains: ["unique-nomatch.test"]
        })

      # Create an owner for the org
      owner = Factories.insert!(:member)
      Core.Authorization.assign_role(owner, org, :owner)

      # Create a new user with non-matching domain
      new_user = Factories.insert!(:member, %{email: "newuser@other-domain.test"})

      # Sync next actions for the new user
      Public.sync_next_actions_for_new_user(new_user)

      # Verify the owner has no NextAction (since no domains match)
      next_actions =
        NextAction.Public.list_next_actions_by_type(owner, Org.NextActions.AddDomainMembers)

      assert Enum.empty?(next_actions)
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
      Core.Authorization.assign_role(owner1, org, :owner)
      Core.Authorization.assign_role(owner2, org, :owner)

      # Create a new user with matching domain
      new_user = Factories.insert!(:member, %{email: "newuser@multi-owner.test"})

      # Sync next actions for the new user
      Public.sync_next_actions_for_new_user(new_user)

      # Verify both owners have a NextAction
      next_actions1 =
        NextAction.Public.list_next_actions_by_type(owner1, Org.NextActions.AddDomainMembers)

      next_actions2 =
        NextAction.Public.list_next_actions_by_type(owner2, Org.NextActions.AddDomainMembers)

      assert length(next_actions1) >= 1
      assert length(next_actions2) >= 1
    end
  end
end
