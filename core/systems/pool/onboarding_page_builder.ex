defmodule Systems.Pool.OnboardingPageBuilder do
  @moduledoc """
  View model builder for `Systems.Pool.OnboardingPage`. Mirrors the shape
  of `Systems.Account.OnboardingPageBuilder` for the page-owned parts
  (steps + current step_view + optional info block + continue button),
  so both pages can share render conventions.

  The step list is participation-aware:

    * Non-participant → `[:join_consent, :features]` — first the
      consent screen (renders `Pool.JoinConsentView`), then the features
      form (renders `Account.FeaturesView`) to capture pool-relevant
      participant attributes like gender and birth year. Features used
      to live in the Account onboarding but is now pool-scoped, since
      it's only meaningful for someone who has just joined a pool.
    * Participant → `[:already_member]` — renders a static info
      block via `step_title` / `step_body`. No step_view is attached
      because there is nothing to interact with (yet — a leave-pool
      action is likely to be added here later).
  """
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Concept.LiveContext
  alias Systems.Pool
  alias Systems.Account

  def view_model(%Pool.Model{} = pool, assigns) do
    current_step_index = Map.get(assigns, :current_step_index, 0)
    user = Map.get(assigns, :current_user)
    steps = build_steps(pool, user, current_step_index)
    current_step = Enum.at(steps, current_step_index)
    live_context = build_live_context(user)

    %{
      pool: pool,
      steps: steps,
      current_step_index: current_step_index,
      current_step: current_step,
      step_view: build_step_view(current_step, pool, live_context),
      step_title: build_step_title(current_step, pool),
      step_body: build_step_body(current_step, pool),
      continue_button: build_continue_button(current_step),
      is_last_step: current_step_index >= length(steps) - 1,
      finish_path: build_finish_path(user),
      hero_title: build_hero_title(current_step, pool),
      progress_dots: build_progress_dots(steps, current_step_index)
    }
  end

  # Progress dots are only meaningful for multi-step flows. A one-step
  # terminal screen like `:already_member` doesn't get one.
  defp build_progress_dots(steps, index) when length(steps) > 1,
    do: %{current: index, total: length(steps)}

  defp build_progress_dots(_steps, _index), do: nil

  # One flow-level title anchors :join_consent + :features so the steps
  # feel like one journey. The terminal :already_member screen has its
  # own step_title and doesn't get a hero.
  defp build_hero_title(:already_member, _pool), do: nil

  # Copy is generic — the pool identity is carried by the pool logo
  # rendered next to the title on the OnboardingPage hero row.
  defp build_hero_title(_step, %Pool.Model{}),
    do: dgettext("eyra-pool", "onboarding.hero.title")

  # Where the flow exits — the user's signed-in landing. Owned by the
  # builder so the page never has to know the URL scheme; a decline or
  # a "continue" on the last step just reads `vm.finish_path`.
  defp build_finish_path(%Account.User{} = user), do: Account.UserAuth.signed_in_path(user)
  defp build_finish_path(_), do: "/"

  # `show_title: false` hides each step view's own title so the page-level
  # `hero_title` is the sole visual anchor across the flow.
  defp build_live_context(%Account.User{id: user_id}),
    do: LiveContext.new(%{user_id: user_id, show_title: false})

  defp build_live_context(_), do: nil

  # Once the user is past step 0, they've opted into the join flow —
  # the step list is committed, even if accepting the consent already
  # flipped them into a real DB participant. Only at index 0 do we
  # consult the DB to choose between the join flow and the
  # "you're already a member" screen.
  defp build_steps(_pool, _user, index) when index > 0, do: [:join_consent, :features]

  defp build_steps(%Pool.Model{} = pool, %Account.User{} = user, 0) do
    if Pool.Public.participant?(pool, user) do
      [:already_member]
    else
      [:join_consent, :features]
    end
  end

  defp build_steps(_pool, _user, 0), do: [:join_consent, :features]

  defp build_step_view(:join_consent, %Pool.Model{} = pool, _live_context) do
    LiveNest.Element.prepare_live_component(
      :join_consent,
      Pool.JoinConsentView,
      id: :join_consent,
      pool: pool,
      show_title: false
    )
  end

  defp build_step_view(:features, _pool, %LiveContext{} = live_context) do
    CoreWeb.Live.Element.prepare_live_view(
      :features_view,
      Account.FeaturesView,
      live_context: live_context
    )
  end

  defp build_step_view(_, _, _), do: nil

  defp build_step_title(:already_member, %Pool.Model{name: name}) do
    dgettext("eyra-pool", "already_member.title", pool_name: name)
  end

  defp build_step_title(_, _), do: nil

  defp build_step_body(_, _), do: nil

  # Join consent has its own accept/decline buttons. Features and
  # already_member both need a page-level exit button — features to
  # advance to the finish, already_member to give the user a way back
  # to home instead of being stranded on an informational screen.
  defp build_continue_button(:features) do
    %{
      action: %{type: :send, event: "continue"},
      face: %{
        type: :primary,
        label: dgettext("eyra-account", "onboarding.continue.button")
      }
    }
  end

  defp build_continue_button(:already_member) do
    %{
      action: %{type: :send, event: "continue"},
      face: %{
        type: :primary,
        label: dgettext("eyra-pool", "already_member.home.button")
      }
    }
  end

  defp build_continue_button(_), do: nil
end
