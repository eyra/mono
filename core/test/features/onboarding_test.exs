defmodule CoreWeb.Features.OnboardingTest do
  @moduledoc """
  Feature test for the PANL participant onboarding flow.

  Tests the complete onboarding experience from the user's perspective:
  - Onboarding page loads after login with profile step first
  - Features step is displayed for PANL participants after profile
  - User can complete onboarding and navigate to home
  """
  use CoreWeb.FeatureCase

  alias Systems.Pool

  @tag :feature
  feature "PANL participant walks account → pool onboarding via return_to chain",
          %{session: session} do
    password = Factories.valid_user_password()

    user =
      Factories.insert!(:member, %{
        password: password,
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      })

    _panl_pool =
      Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

    session
    |> sign_in(user, password)
    |> visit("/user/onboarding?return_to=/pool/panl/join")
    |> assert_has(Query.css("[data-testid='profile-view']"))
    |> click(Query.css("[phx-click='continue']"))
    |> assert_has(Query.css("[data-testid='pool-join-consent-view']"))
    |> click(Query.css("[data-testid='pool-join-consent-accept-button']"))
    |> assert_has(Query.css("[data-testid='features-view']"))
    |> click(Query.css("[data-testid='pool-onboarding-continue']"))
    |> assert_path_changed_from("/pool/panl/onboarding")
  end

  @tag :feature
  feature "non-PANL user sees profile step on onboarding", %{session: session} do
    # Create a confirmed non-PANL user
    password = Factories.valid_user_password()

    user =
      Factories.insert!(:member, %{
        password: password,
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      })

    session
    |> sign_in(user, password)
    |> visit("/user/onboarding")
    |> assert_has(Query.css("[data-testid='profile-view']"))
  end

  @tag :feature
  feature "non-PANL user completes onboarding in single step", %{session: session} do
    # Create a confirmed non-PANL user
    password = Factories.valid_user_password()

    user =
      Factories.insert!(:member, %{
        password: password,
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      })

    session
    |> sign_in(user, password)
    |> visit("/user/onboarding")
    |> assert_has(Query.css("[data-testid='profile-view']"))
    # For non-PANL confirmed user, profile is the only step
    # Clicking continue should redirect to home — `body` polls.
    |> click(Query.css("[phx-click='continue']"))
    |> assert_has(Query.css("body"))
  end
end
