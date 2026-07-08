defmodule Systems.Pool.OnboardingPageBuilderTest do
  use Core.DataCase, async: true
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Concept.LiveContext
  alias Systems.Account
  alias Systems.Pool

  # Where the flow exits — reused across finish_path assertions.
  defp expected_finish_path(user), do: Account.UserAuth.signed_in_path(user)

  setup do
    user = Factories.insert!(:member)
    pool = Factories.insert!(:pool, %{name: "Panl", director: :citizen})
    {:ok, user: user, pool: pool}
  end

  describe "view_model/2 for a non-member (index 0)" do
    test "steps are [:join_consent, :features]", %{user: user, pool: pool} do
      vm = Pool.OnboardingPageBuilder.view_model(pool, %{current_user: user})

      assert vm.steps == [:join_consent, :features]
    end

    test "first step is join_consent with JoinConsentView", %{user: user, pool: pool} do
      vm = Pool.OnboardingPageBuilder.view_model(pool, %{current_user: user})

      assert vm.current_step == :join_consent
      assert vm.step_view.implementation == Pool.JoinConsentView
      assert vm.step_view.options[:pool] == pool
    end

    test "join_consent has no continue button (view renders its own)",
         %{user: user, pool: pool} do
      vm = Pool.OnboardingPageBuilder.view_model(pool, %{current_user: user})

      assert vm.continue_button == nil
    end

    test "is_last_step is false", %{user: user, pool: pool} do
      vm = Pool.OnboardingPageBuilder.view_model(pool, %{current_user: user})

      assert vm.is_last_step == false
    end
  end

  describe "view_model/2 for a non-member on the features step (index 1)" do
    test "second step is features with FeaturesView + user_id in context", %{
      user: user,
      pool: pool
    } do
      vm =
        Pool.OnboardingPageBuilder.view_model(pool, %{
          current_user: user,
          current_step_index: 1
        })

      assert vm.current_step == :features
      assert vm.step_view.implementation == Account.FeaturesView

      assert %LiveContext{data: %{user_id: user_id}} = vm.step_view.options[:live_context]
      assert user_id == user.id
    end

    test "features has a continue button", %{user: user, pool: pool} do
      vm =
        Pool.OnboardingPageBuilder.view_model(pool, %{
          current_user: user,
          current_step_index: 1
        })

      assert vm.continue_button.action.type == :send
      assert vm.continue_button.action.event == "continue"
      assert vm.continue_button.face.type == :primary
    end

    test "is_last_step is true", %{user: user, pool: pool} do
      vm =
        Pool.OnboardingPageBuilder.view_model(pool, %{
          current_user: user,
          current_step_index: 1
        })

      assert vm.is_last_step == true
    end

    test "step list stays [:join_consent, :features] even after DB flip mid-flow", %{
      user: user,
      pool: pool
    } do
      # After accepting at step 0 the user is now a DB member. But the
      # builder must NOT swap to `[:already_member]` — `current_step_index`
      # is already 1 and would run off the end of a rebuilt one-step list.
      # Index > 0 is the "we're mid-flow" signal.
      Pool.Public.add_participant!(pool, user)

      vm =
        Pool.OnboardingPageBuilder.view_model(pool, %{
          current_user: user,
          current_step_index: 1
        })

      assert vm.steps == [:join_consent, :features]
      assert vm.current_step == :features
    end
  end

  describe "view_model/2 for an existing member (index 0)" do
    setup %{user: user, pool: pool} do
      Pool.Public.add_participant!(pool, user)
      :ok
    end

    test "steps is [:already_member]", %{user: user, pool: pool} do
      vm = Pool.OnboardingPageBuilder.view_model(pool, %{current_user: user})

      assert vm.steps == [:already_member]
      assert vm.current_step == :already_member
    end

    test "no step_view is attached (nothing to interact with)", %{user: user, pool: pool} do
      vm = Pool.OnboardingPageBuilder.view_model(pool, %{current_user: user})

      assert vm.step_view == nil
    end

    test "step_title carries the info message; step_body is nil (title-only screen)",
         %{user: user, pool: pool} do
      vm = Pool.OnboardingPageBuilder.view_model(pool, %{current_user: user})

      assert vm.step_title ==
               dgettext("eyra-pool", "already_member.title", pool_name: pool.name)

      assert vm.step_body == nil
    end

    test "has a home button (labelled for exit)", %{user: user, pool: pool} do
      vm = Pool.OnboardingPageBuilder.view_model(pool, %{current_user: user})

      assert vm.continue_button.action.type == :send
      assert vm.continue_button.action.event == "continue"

      assert vm.continue_button.face.label ==
               dgettext("eyra-pool", "already_member.home.button")
    end
  end

  describe "view_model/2 defaults" do
    test "defaults current_step_index to 0", %{user: user, pool: pool} do
      vm = Pool.OnboardingPageBuilder.view_model(pool, %{current_user: user})

      assert vm.current_step_index == 0
    end

    test "exposes the pool in the view model", %{user: user, pool: pool} do
      vm = Pool.OnboardingPageBuilder.view_model(pool, %{current_user: user})

      assert vm.pool == pool
    end
  end

  describe "view_model/2 finish_path" do
    test "returns the user's signed-in landing", %{user: user, pool: pool} do
      vm = Pool.OnboardingPageBuilder.view_model(pool, %{current_user: user})

      assert vm.finish_path == expected_finish_path(user)
    end

    test "falls back to '/' when no user is present", %{pool: pool} do
      vm = Pool.OnboardingPageBuilder.view_model(pool, %{})

      assert vm.finish_path == "/"
    end
  end
end
