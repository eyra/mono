defmodule Systems.Admin.SystemViewBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

  alias Core.Factories
  alias Systems.Admin.SystemViewBuilder

  describe "view_model/2" do
    test "returns correct structure" do
      vm = SystemViewBuilder.view_model(nil, %{})

      assert is_binary(vm.bank_accounts_title)
      assert is_binary(vm.bank_accounts_new_title)
      assert is_list(vm.bank_accounts)
      assert is_list(vm.bank_account_items)
      assert is_integer(vm.bank_account_count)
      assert is_binary(vm.citizen_pools_title)
      assert is_binary(vm.citizen_pools_new_title)
      assert is_list(vm.citizen_pools)
      assert is_list(vm.citizen_pool_items)
      assert is_integer(vm.citizen_pool_count)
    end

    test "returns locale from assigns" do
      vm = SystemViewBuilder.view_model(nil, %{locale: :nl})

      assert vm.locale == :nl
    end

    test "returns current_user from assigns" do
      user = Factories.insert!(:member)
      vm = SystemViewBuilder.view_model(nil, %{current_user: user})

      assert vm.current_user.id == user.id
    end
  end

  describe "build_bank_account_modal/2" do
    test "returns modal configuration for new bank account" do
      user = Factories.insert!(:member)
      modal = SystemViewBuilder.build_bank_account_modal(nil, user)

      assert modal.element.id == "bank_account_form"
      assert modal.style == :compact
    end
  end

  describe "build_citizen_pool_modal/3" do
    test "returns modal configuration for new citizen pool" do
      user = Factories.insert!(:member)
      modal = SystemViewBuilder.build_citizen_pool_modal(nil, user, :en)

      assert modal.element.id == "pool_form"
      assert modal.style == :compact
    end
  end
end
