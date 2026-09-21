defmodule Systems.Account.OnboardingPageBuilder do
  @moduledoc """
  Builder for OnboardingPage that determines which steps to show and manages step progression.
  """
  use CoreWeb, :verified_routes
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Concept.LiveContext
  alias Systems.Account

  def view_model(%Account.User{email: email} = user, assigns) do
    current_step_index = Map.get(assigns, :current_step_index, 0)
    steps = build_steps(user, current_step_index)
    current_step = Enum.at(steps, current_step_index)

    # `show_title: false` in the shared context means each step view drops
    # its own title so the page-level `hero_title` is the sole visual
    # anchor across the flow. Each callsite that mounts the same view
    # outside the flow (e.g. Account settings tabs) passes
    # `show_title: true`.
    live_context =
      LiveContext.new(%{
        user_id: user.id,
        show_title: false
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
      continue_button: build_continue_button(current_step),
      progress_dots: build_progress_dots(steps, current_step_index)
    }
  end

  # Progress dots only appear for multi-step flows. A single-step flow
  # (activated non-PANL user with just :profile) doesn't need them.
  defp build_progress_dots(steps, index) when length(steps) > 1,
    do: %{current: index, total: length(steps)}

  defp build_progress_dots(_steps, _index), do: nil

  # Once we're past step 0 the flow is committed — a passwordless user who
  # just accepted terms is now activated in the DB, but we still want to
  # show them as being at step 2 of 2 in the same [:terms_and_privacy, :profile]
  # flow. Same trick as `Pool.OnboardingPageBuilder.build_steps/3`.
  defp build_steps(user, index) when index > 0 do
    cond do
      Account.Public.passwordless?(user) -> [:terms_and_privacy, :profile]
      not Account.Public.activated?(user) -> [:profile, :activate_account]
      true -> [:profile]
    end
  end

  defp build_steps(user, 0) do
    steps = [:profile]

    cond do
      Account.Public.activated?(user) ->
        steps

      Account.Public.passwordless?(user) ->
        [:terms_and_privacy | steps]

      true ->
        steps ++ [:activate_account]
    end
  end

  defp build_step_view(:profile, _user, live_context) do
    profile_context =
      LiveContext.extend(live_context, %{
        show_signout_button: false,
        show_email: false
      })

    CoreWeb.Live.Element.prepare_live_view(
      :profile_view,
      Account.ProfileView,
      live_context: profile_context
    )
  end

  defp build_step_view(:terms_and_privacy, _user, live_context) do
    CoreWeb.Live.Element.prepare_live_view(
      :terms_and_privacy_view,
      Account.TermsAndPrivacyView,
      live_context: live_context
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

  defp build_continue_button(:terms_and_privacy), do: nil

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
