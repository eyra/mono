defmodule Systems.Account.OnboardingPageBuilder do
  @moduledoc """
  Builder for OnboardingPage that determines which steps to show and manages step progression.
  """
  use CoreWeb, :verified_routes
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Concept.LiveContext
  alias Systems.Account
  alias Systems.Pool

  def view_model(%Account.User{email: email} = user, assigns) do
    steps = build_steps(user)
    current_step_index = Map.get(assigns, :current_step_index, 0)
    current_step = Enum.at(steps, current_step_index)

    live_context =
      LiveContext.new(%{
        user_id: user.id
      })

    step_view =
      if current_step do
        build_step_view(current_step, user, live_context)
      else
        nil
      end

    %{
      hero_title: dgettext("eyra-account", "onboarding.hero.title"),
      steps: steps,
      current_step_index: current_step_index,
      current_step: current_step,
      step_view: step_view,
      step_title: build_step_title(current_step),
      step_body: build_step_body(current_step, email),
      is_last_step: current_step_index >= length(steps) - 1,
      continue_button: build_continue_button(current_step)
    }
  end

  defp build_steps(user) do
    steps = [:profile]

    steps =
      if Pool.Public.participant?(:panl, user) do
        steps ++ [:features]
      else
        steps
      end

    if Account.Public.activated?(user) do
      steps
    else
      steps ++ [:activate_account]
    end
  end

  defp build_step_view(:features, _user, live_context) do
    CoreWeb.Live.Element.prepare_live_view(
      :features_view,
      Account.FeaturesView,
      live_context: live_context
    )
  end

  defp build_step_view(:profile, _user, live_context) do
    profile_context =
      LiveContext.extend(live_context, %{
        show_signout_button: false,
        show_email: false,
        show_top_margin: false
      })

    CoreWeb.Live.Element.prepare_live_view(
      :profile_view,
      Account.ProfileView,
      live_context: profile_context
    )
  end

  defp build_step_view(_, _, _), do: nil

  defp build_step_title(:activate_account) do
    dgettext("eyra-account", "onboarding.activate_account.title")
  end

  defp build_step_title(_), do: nil

  defp build_step_body(:activate_account, email) do
    dgettext("eyra-account", "onboarding.activate_account.body", email: email)
  end

  defp build_step_body(_, _), do: nil

  defp build_continue_button(:activate_account) do
    %{
      action: %{type: :send, event: "continue"},
      face: %{
        type: :primary,
        label: dgettext("eyra-account", "onboarding.activate_account.continue.button")
      }
    }
  end

  defp build_continue_button(_) do
    %{
      action: %{type: :send, event: "continue"},
      face: %{
        type: :primary,
        label: dgettext("eyra-account", "onboarding.continue.button")
      }
    }
  end
end
