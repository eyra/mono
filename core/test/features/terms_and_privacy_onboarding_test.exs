defmodule CoreWeb.Features.TermsAndPrivacyOnboardingTest do
  @moduledoc """
  Feature test for the terms-and-privacy onboarding flow using the Mock OAuth provider.

  Covers the full chain: signup page → initiator plug → callback creates user
  → onboarding page → Continue (with and without accepting terms) → signed-in
  page.
  """
  use CoreWeb.FeatureCase

  setup do
    original_providers =
      Application.get_env(:core, :account, []) |> Keyword.get(:auth_providers, [])

    account = Application.get_env(:core, :account, [])

    Application.put_env(
      :core,
      :account,
      Keyword.put(account, :auth_providers, [:mock])
    )

    on_exit(fn ->
      account = Application.get_env(:core, :account, [])

      Application.put_env(
        :core,
        :account,
        Keyword.put(account, :auth_providers, original_providers)
      )
    end)

    :ok
  end

  @tag :feature
  feature "first-time mock user goes through onboarding to signed-in page", %{session: session} do
    session
    |> visit("/user/auth/mock/reset")
    |> assert_has(Query.css("[data-phx-main].phx-connected"))
    |> assert_has(Query.css("[data-testid='auth-signin-button']"))
    |> click(Query.css("[data-testid='auth-signin-button']"))
    |> assert_has(Query.css("[data-phx-main].phx-connected"))
    # First step: terms-and-privacy
    |> assert_has(Query.css("[data-testid='terms-and-privacy-onboarding-terms']"))
    # Continue without accepting terms → flash error
    |> click(Query.css("[data-testid='onboarding-continue']"))
    |> assert_has(Query.css("[role='alert']"))
    # Accept terms and continue → advance to profile step
    |> click(Query.css("[data-testid='terms-and-privacy-onboarding-terms']"))
    |> click(Query.css("[data-testid='onboarding-continue']"))
    |> assert_has(Query.css("[data-testid='profile-view']"))
    # Continue past profile step → land on creator home
    |> click(Query.css("[data-testid='onboarding-continue']"))
    |> assert_has(Query.text("Start your first project", count: 2))
  end
end
