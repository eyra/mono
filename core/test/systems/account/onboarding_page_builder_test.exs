defmodule Systems.Account.OnboardingPageBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Account
  alias Systems.Pool

  describe "view_model/2 with confirmed PANL participant" do
    setup do
      user = Factories.insert!(:member)

      panl_pool =
        Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      Pool.Public.add_participant!(panl_pool, user)

      user = Core.Repo.preload(user, [:features, :profile])

      %{user: user}
    end

    test "builds view model with hero_title", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

      assert vm.hero_title == dgettext("eyra-account", "onboarding.hero.title")
    end

    test "includes profile and features steps (no activate_account)", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

      assert vm.steps == [:profile, :features]
      refute :activate_account in vm.steps
    end

    test "first step is profile", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

      assert vm.current_step == :profile
      assert vm.step_view != nil
      assert vm.step_view.implementation == Account.ProfileView
    end

    test "features step has features view", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 1})

      assert vm.current_step == :features
      assert vm.step_view != nil
      assert vm.step_view.implementation == Account.FeaturesView
    end

    test "is_last_step is false on first step", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

      assert vm.is_last_step == false
    end

    test "is_last_step is true on last step", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 1})

      assert vm.is_last_step == true
    end

    test "builds continue button", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

      assert vm.continue_button.action.type == :send
      assert vm.continue_button.action.event == "continue"
      assert vm.continue_button.face.type == :primary

      assert vm.continue_button.face.label ==
               dgettext("eyra-account", "onboarding.continue.button")
    end
  end

  describe "view_model/2 with unconfirmed PANL participant" do
    setup do
      user = Factories.insert!(:member, %{confirmed_at: nil})

      panl_pool =
        Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      Pool.Public.add_participant!(panl_pool, user)

      user = Core.Repo.preload(user, [:features, :profile])

      %{user: user}
    end

    test "includes activate_account as last step", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

      assert vm.steps == [:profile, :features, :activate_account]
    end

    test "activate_account step has no step_view but has title and body", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 2})

      assert vm.current_step == :activate_account
      assert vm.step_view == nil
      assert vm.step_title == dgettext("eyra-account", "onboarding.activate_account.title")
      assert vm.step_body != nil
    end

    test "activate_account step has special continue button label", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 2})

      assert vm.continue_button.face.label ==
               dgettext("eyra-account", "onboarding.activate_account.continue.button")
    end
  end

  describe "view_model/2 with confirmed non-PANL user" do
    setup do
      user = Factories.insert!(:member)
      user = Core.Repo.preload(user, [:features, :profile])

      %{user: user}
    end

    test "has only profile step", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

      assert vm.steps == [:profile]
    end

    test "first step is profile with step_view", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

      assert vm.step_view != nil
      assert vm.step_view.implementation == Account.ProfileView
    end
  end

  describe "view_model/2 with unconfirmed non-PANL user" do
    setup do
      user = Factories.insert!(:member, %{confirmed_at: nil})
      user = Core.Repo.preload(user, [:features, :profile])

      %{user: user}
    end

    test "has profile and activate_account steps", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

      assert vm.steps == [:profile, :activate_account]
    end
  end

  describe "view_model/2 defaults" do
    setup do
      user = Factories.insert!(:member)

      panl_pool =
        Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      Pool.Public.add_participant!(panl_pool, user)

      user = Core.Repo.preload(user, [:features, :profile])

      %{user: user}
    end

    test "defaults current_step_index to 0", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{})

      assert vm.current_step_index == 0
    end
  end
end
