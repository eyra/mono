defmodule CoreWeb.Features.TermsAndPrivacyOnboardingTest do
  @moduledoc """
  Feature test for the terms-and-privacy onboarding flow using the Mock OAuth provider.

  Covers the full chain: mock reset → mock sign-in page → callback creates user
  → onboarding page → Continue (with and without accepting terms) → signed-in
  page.
  """
  use CoreWeb.FeatureCase

  setup do
    account = Application.get_env(:core, :account, [])
    auth_methods = Keyword.fetch!(account, :auth_methods)

    Application.put_env(
      :core,
      :account,
      Keyword.put(
        account,
        :auth_methods,
        Map.put(auth_methods, :mock, %{provider: true, satellite: false})
      )
    )

    on_exit(fn -> Application.put_env(:core, :account, account) end)

    :ok
  end

  @tag :feature
  feature "first-time mock user goes through onboarding to signed-in page", %{session: session} do
    session
    |> visit("/user/auth/mock/reset")
    # Mock identity provider: the form is prefilled with example@mock.com and
    # submits over the LiveView socket.
    |> assert_connected("[data-testid='mock-auth-signin-page']")
    |> click(Query.css("[data-testid='mock-auth-submit-button']"))
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
