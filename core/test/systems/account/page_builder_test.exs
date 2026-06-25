defmodule Systems.Account.PageBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Account
  alias Systems.Pool

  describe "view_model/2" do
    setup do
      user = Factories.insert!(:member)
      user = Core.Repo.preload(user, [:features, :profile])

      %{user: user}
    end

    test "builds view model with title", %{user: user} do
      vm = Account.PageBuilder.view_model(user, %{})

      assert vm.title == dgettext("eyra-account", "profile.title")
    end

    test "builds view model with user", %{user: user} do
      vm = Account.PageBuilder.view_model(user, %{})

      assert vm.user == user
    end

    test "builds view model with active_menu_item", %{user: user} do
      vm = Account.PageBuilder.view_model(user, %{})

      assert vm.active_menu_item == :profile
    end

    test "includes profile item for regular user", %{user: user} do
      vm = Account.PageBuilder.view_model(user, %{})

      item_ids = Enum.map(vm.items, & &1.id)
      assert :profile in item_ids
    end

    test "excludes features item for non-PANL user", %{user: user} do
      vm = Account.PageBuilder.view_model(user, %{})

      item_ids = Enum.map(vm.items, & &1.id)
      refute :features in item_ids
    end

    test "includes features item for PANL participant" do
      user = Factories.insert!(:member)

      panl_pool =
        Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      Pool.Public.add_participant!(panl_pool, user)

      user = Core.Repo.preload(user, [:features, :profile])
      vm = Account.PageBuilder.view_model(user, %{})

      item_ids = Enum.map(vm.items, & &1.id)
      assert :profile in item_ids
      assert :features in item_ids
    end

    test "items have LiveNest element structure", %{user: user} do
      vm = Account.PageBuilder.view_model(user, %{})

      profile_item = Enum.find(vm.items, &(&1.id == :profile))
      assert profile_item != nil
      assert Map.has_key?(profile_item, :element)
      assert %LiveNest.Element{} = profile_item.element
      assert profile_item.element.implementation == Account.ProfileView
    end
  end

  describe "tab_keys/1" do
    test "includes features key when user is PANL participant" do
      user = Factories.insert!(:member)

      panl_pool =
        Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      Pool.Public.add_participant!(panl_pool, user)

      result = Account.PageBuilder.tab_keys(user)

      assert result == [:profile, :payouts, :features]
    end

    test "excludes features key when user is not PANL participant" do
      user = Factories.insert!(:member)
      Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      result = Account.PageBuilder.tab_keys(user)

      assert result == [:profile, :payouts]
    end

    test "excludes features key when PANL pool does not exist" do
      user = Factories.insert!(:member)

      if panl_pool = Pool.Public.get_panl() do
        Repo.delete(panl_pool)
      end

      result = Account.PageBuilder.tab_keys(user)

      assert result == [:profile, :payouts]
    end
  end
end
