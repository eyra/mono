defmodule Systems.Org.OwnersViewBuilderTest do
  use Core.DataCase

  alias Core.Factories
  alias Systems.Org.OwnersViewBuilder

  describe "view_model/2" do
    test "returns owners list from org" do
      user1 = Factories.insert!(:member)
      user2 = Factories.insert!(:member)
      org = Factories.insert!(:org_node, %{identifier: ["owners_vm_org"]})

      Core.Authorization.assign_role(user1, org, :owner)
      Core.Authorization.assign_role(user2, org, :owner)

      vm = OwnersViewBuilder.view_model(org, %{})

      assert length(vm.owners) == 2
      owner_ids = Enum.map(vm.owners, & &1.id)
      assert user1.id in owner_ids
      assert user2.id in owner_ids
    end

    test "returns empty list when org has no owners" do
      org = Factories.insert!(:org_node, %{identifier: ["no_owners_org"]})

      vm = OwnersViewBuilder.view_model(org, %{})

      assert vm.owners == []
    end

    test "returns empty list when org has no auth_node" do
      org = %Systems.Org.NodeModel{id: 999, auth_node_id: nil}

      vm = OwnersViewBuilder.view_model(org, %{})

      assert vm.owners == []
    end
  end
end
