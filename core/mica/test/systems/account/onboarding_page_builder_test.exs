defmodule Systems.Account.OnboardingPageBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Account

  # Note: `:features` has moved to `Systems.Pool.OnboardingPageBuilder`.
  # These tests only cover the account-level steps (profile, terms,
  # activate_account) — pool participation no longer affects this list.

  describe "view_model/2 with confirmed user" do
    setup do
      user = Factories.insert!(:member)
      user = Core.Repo.preload(user, [:features, :profile])
      %{user: user}
    end

    test "builds view model with hero_title", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

      assert vm.hero_title == dgettext("eyra-account", "onboarding.hero.title")
    end

    test "has only the profile step", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

      assert vm.steps == [:profile]
    end

    test "first step is profile with ProfileView", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

      assert vm.current_step == :profile
      assert vm.step_view.implementation == Account.ProfileView
    end

    test "is_last_step is true (single step)", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

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

  describe "view_model/2 with unconfirmed user" do
    setup do
      user = Factories.insert!(:member, %{confirmed_at: nil})
      user = Core.Repo.preload(user, [:features, :profile])
      %{user: user}
    end

    test "has profile and activate_account steps", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

      assert vm.steps == [:profile, :activate_account]
    end

    test "activate_account step has no step_view but has title and body", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 1})

      assert vm.current_step == :activate_account
      assert vm.step_view == nil
      assert vm.step_title == dgettext("eyra-account", "onboarding.activate_account.title")
      assert vm.step_body != nil
    end

    test "activate_account step has special continue button label", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 1})

      assert vm.continue_button.face.label ==
               dgettext("eyra-account", "onboarding.activate_account.continue.button")
    end
  end

  describe "view_model/2 with unactivated passwordless user (SSO)" do
    setup do
      {:ok, user} =
        %Account.User{}
        |> Account.User.sso_changeset(%{
          email: "sso-#{System.unique_integer([:positive])}@example.com",
          displayname: "SSO User",
          creator: true,
          verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })
        |> Core.Repo.insert()

      user = Core.Repo.preload(user, [:features, :profile])

      %{user: user}
    end

    test "first step is terms_and_privacy", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

      assert vm.current_step == :terms_and_privacy
      assert hd(vm.steps) == :terms_and_privacy
    end

    test "step_view is TermsAndPrivacyView", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

      assert vm.step_view.implementation == Account.TermsAndPrivacyView
    end

    test "step_title and step_body are nil (rendered by the view)", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

      assert vm.step_title == nil
      assert vm.step_body == nil
    end

    test "continue_button is nil (the view renders its own)", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

      assert vm.continue_button == nil
    end

    test "no activate_account step (terms step activates them)", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

      refute :activate_account in vm.steps
    end
  end

  describe "view_model/2 with unactivated passwordless user (OTP)" do
    setup do
      email = "otp-#{System.unique_integer([:positive])}@example.com"
      {:ok, user} = Account.Public.register_user_with_email(email)
      user = Core.Repo.preload(user, [:features, :profile])

      %{user: user}
    end

    test "first step is terms_and_privacy", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

      assert vm.current_step == :terms_and_privacy
      assert hd(vm.steps) == :terms_and_privacy
    end

    test "step_view is TermsAndPrivacyView", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

      assert vm.step_view.implementation == Account.TermsAndPrivacyView
    end

    test "no activate_account step (terms step activates them)", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{current_step_index: 0})

      refute :activate_account in vm.steps
    end
  end

  describe "view_model/2 defaults" do
    setup do
      user = Factories.insert!(:member)
      user = Core.Repo.preload(user, [:features, :profile])
      %{user: user}
    end

    test "defaults current_step_index to 0", %{user: user} do
      vm = Account.OnboardingPageBuilder.view_model(user, %{})

      assert vm.current_step_index == 0
    end
  end
end
