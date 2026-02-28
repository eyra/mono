defmodule Systems.Account.UserProfilePageBuilderTest do
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
      vm = Account.UserProfilePageBuilder.view_model(user, %{})

      assert vm.title == dgettext("eyra-account", "profile.title")
    end

    test "builds view model with user", %{user: user} do
      vm = Account.UserProfilePageBuilder.view_model(user, %{})

      assert vm.user == user
    end

    test "builds view model with active_menu_item", %{user: user} do
      vm = Account.UserProfilePageBuilder.view_model(user, %{})

      assert vm.active_menu_item == :profile
    end

    test "includes profile tab for regular user", %{user: user} do
      vm = Account.UserProfilePageBuilder.view_model(user, %{})

      tab_ids = Enum.map(vm.tabs, & &1.id)
      assert :profile in tab_ids
    end

    test "excludes features tab for non-PANL user", %{user: user} do
      vm = Account.UserProfilePageBuilder.view_model(user, %{})

      tab_ids = Enum.map(vm.tabs, & &1.id)
      refute :features in tab_ids
    end

    test "includes features tab for PANL participant" do
      user = Factories.insert!(:member)

      panl_pool =
        Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      Pool.Public.add_participant!(panl_pool, user)

      user = Core.Repo.preload(user, [:features, :profile])
      vm = Account.UserProfilePageBuilder.view_model(user, %{})

      tab_ids = Enum.map(vm.tabs, & &1.id)
      assert :profile in tab_ids
      assert :features in tab_ids
    end

    test "tabs have LiveNest element structure", %{user: user} do
      vm = Account.UserProfilePageBuilder.view_model(user, %{})

      profile_tab = Enum.find(vm.tabs, &(&1.id == :profile))
      assert profile_tab != nil
      assert Map.has_key?(profile_tab, :element)
      assert %LiveNest.Element{} = profile_tab.element
      assert profile_tab.element.implementation == Account.ProfileView
    end
  end

  describe "tab_keys/1" do
    test "includes features key when user is PANL participant" do
      user = Factories.insert!(:member)

      panl_pool =
        Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      Pool.Public.add_participant!(panl_pool, user)

      result = Account.UserProfilePageBuilder.tab_keys(user)

      assert result == [:profile, :features]
    end

    test "excludes features key when user is not PANL participant" do
      user = Factories.insert!(:member)
      Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      result = Account.UserProfilePageBuilder.tab_keys(user)

      assert result == [:profile]
    end

    test "excludes features key when PANL pool does not exist" do
      user = Factories.insert!(:member)

      if panl_pool = Pool.Public.get_panl() do
        Repo.delete(panl_pool)
      end

      result = Account.UserProfilePageBuilder.tab_keys(user)

      assert result == [:profile]
    end
  end
end
