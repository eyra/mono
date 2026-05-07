defmodule Systems.Org.AdminsModalViewBuilderTest do
  use Core.DataCase

  alias Core.Factories
  alias Systems.Org.AdminsModalViewBuilder

  describe "view_model/2" do
    test "returns current owners as people" do
      owner1 = Factories.insert!(:creator)
      owner2 = Factories.insert!(:creator)
      org = Factories.insert!(:org_node, %{identifier: ["admins_vm_org"]})

      Core.Authorization.assign_role(owner1, org, :owner)
      Core.Authorization.assign_role(owner2, org, :owner)

      vm = AdminsModalViewBuilder.view_model(org, %{})

      assert length(vm.people) == 2
      people_ids = Enum.map(vm.people, & &1.id)
      assert owner1.id in people_ids
      assert owner2.id in people_ids
    end

    test "returns available creators as users" do
      creator1 = Factories.insert!(:creator)
      creator2 = Factories.insert!(:creator)
      org = Factories.insert!(:org_node, %{identifier: ["avail_users_org"]})

      # creator1 is already an owner, so should not be in users
      Core.Authorization.assign_role(creator1, org, :owner)

      vm = AdminsModalViewBuilder.view_model(org, %{})

      user_ids = Enum.map(vm.users, & &1.id)
      refute creator1.id in user_ids
      assert creator2.id in user_ids
    end

    test "returns title in view model" do
      org = Factories.insert!(:org_node, %{identifier: ["title_vm_org"]})

      vm = AdminsModalViewBuilder.view_model(org, %{})

      assert is_binary(vm.title)
      assert vm.title != ""
    end

    test "returns empty people list when org has no owners" do
      org = Factories.insert!(:org_node, %{identifier: ["no_owners_modal_org"]})

      vm = AdminsModalViewBuilder.view_model(org, %{})

      assert vm.people == []
    end
  end
end
