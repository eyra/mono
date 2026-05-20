defmodule CoreWeb.Features.PanlSignupLocaleTest do
  @moduledoc """
  Regression: after registering via `/user/signup/participant`, the
  post-signup landing pages (`/user/onboarding` for PaNL,
  `/user/await-confirmation` otherwise) should keep the browser locale
  (NL) instead of falling back to English.
  """
  use CoreWeb.FeatureCase

  alias Systems.Pool

  @nl_capabilities %{
    chromeOptions: %{
      args: [
        "--lang=nl-NL",
        "--headless",
        "--no-sandbox",
        "--disable-dev-shm-usage",
        "--disable-gpu",
        "--window-size=1280,800"
      ],
      prefs: %{"intl.accept_languages" => "nl-NL,nl"}
    }
  }

  @sessions [[capabilities: @nl_capabilities]]
  @tag :feature
  feature "PaNL signup keeps browser locale on /user/onboarding", %{session: session} do
    Pool.Assembly.get_or_create_panl()

    password = Factories.valid_user_password()
    email = "panl-locale-#{System.unique_integer([:positive])}@example.com"

    session
    |> visit("/user/signup/participant?post_signup_action=add_to_panl")
    |> assert_has(Query.css("[data-phx-main].phx-connected"))
    |> assert_has(Query.text("Maak een account aan"))
    |> fill_in(Query.css("input[name='user[email]']"), with: email)
    |> fill_in(Query.css("input[name='user[password]']"), with: password)
    |> click(
      Query.css("[data-selector-item='next_privacy_policy_accepted'] .selector-icon-inactive")
    )
    |> click(
      Query.css("[data-selector-item='panl_privacy_policy_accepted'] .selector-icon-inactive")
    )
    |> click(Query.css("button[type='submit']"))
    |> assert_has(Query.css("[data-testid='onboarding-continue']", text: "Doorgaan"))
  end

  @sessions [[capabilities: @nl_capabilities]]
  @tag :feature
  feature "participant signup keeps browser locale on /user/await-confirmation", %{
    session: session
  } do
    password = Factories.valid_user_password()
    email = "await-locale-#{System.unique_integer([:positive])}@example.com"

    session
    |> visit("/user/signup/participant")
    |> assert_has(Query.css("[data-phx-main].phx-connected"))
    |> assert_has(Query.text("Maak een account aan"))
    |> fill_in(Query.css("input[name='user[email]']"), with: email)
    |> fill_in(Query.css("input[name='user[password]']"), with: password)
    |> click(
      Query.css("[data-selector-item='next_privacy_policy_accepted'] .selector-icon-inactive")
    )
    |> click(Query.css("button[type='submit']"))
    |> assert_has(Query.css("[data-phx-main].phx-connected"))
    |> assert_has(Query.text("Activeer je account"))
  end
end
