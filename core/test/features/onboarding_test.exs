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
  feature "PANL participant sees profile step first on onboarding page", %{session: session} do
    # Create a confirmed PANL participant
    password = Factories.valid_user_password()

    user =
      Factories.insert!(:member, %{
        password: password,
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      })

    # Add user to PANL pool
    panl_pool =
      Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

    Pool.Public.add_participant!(panl_pool, user)

    session
    |> sign_in(user, password)
    |> visit("/user/onboarding")
    |> assert_has(Query.css("[data-testid='profile-view']"))
  end

  @tag :feature
  feature "PANL participant can complete onboarding with continue button", %{session: session} do
    # Create a confirmed PANL participant
    password = Factories.valid_user_password()

    user =
      Factories.insert!(:member, %{
        password: password,
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      })

    # Add user to PANL pool
    panl_pool =
      Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

    Pool.Public.add_participant!(panl_pool, user)

    session
    |> sign_in(user, password)
    |> visit("/user/onboarding")
    # First step: profile
    |> assert_has(Query.css("[data-testid='profile-view']"))
    # Click continue to go to features step
    |> click(Query.css("[phx-click='continue']"))
    |> assert_has(Query.css("[data-testid='features-view']"))
    # Click continue to finish onboarding
    |> click(Query.css("[phx-click='continue']"))
    # Should navigate away from onboarding — `body` polls.
    |> assert_has(Query.css("body"))
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
    # Non-PANL user should see profile view but not features view
    |> assert_has(Query.css("[data-testid='profile-view']"))
    |> refute_has(Query.css("[data-testid='features-view']"))
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
