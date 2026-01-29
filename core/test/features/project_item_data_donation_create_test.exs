defmodule CoreWeb.Features.ProjectItemDataDonationCreateTest do
  @moduledoc """
  Feature test for creating a data donation project item.
  """
  use CoreWeb.FeatureCase

  @card_selector "[data-testid^='card_']"

  @tag :feature
  feature "researcher can create a data donation assignment", %{session: session} do
    password = Factories.valid_user_password()

    researcher =
      Factories.insert!(:member, %{
        password: password,
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        creator: true
      })

    # Login as researcher - use tab=creator param to avoid JS tab switching race conditions
    session
    |> visit("/user/signin?tab=creator")
    |> fill_in(Query.css("[data-testid='signin-email-input']"), with: researcher.email)
    |> fill_in(Query.css("[data-testid='signin-password-input']"), with: password)
    |> click(Query.css("[data-testid='signin-submit-button']"))

    # Create project
    session
    |> assert_has(Query.css("[data-testid='create-first-project-button']"))
    |> click(Query.css("[data-testid='create-first-project-button']"))

    # Navigate into the project
    session
    |> assert_has(Query.css(@card_selector, count: 1))
    |> click(Query.css(@card_selector))

    # Wait for LiveView to be connected
    session |> assert_has(Query.css("[data-phx-main].phx-connected"))

    # Create assignment
    session
    |> assert_has(Query.css("[data-testid='create-first-item-button']"))
    |> click(Query.css("[data-testid='create-first-item-button']"))
    |> assert_has(Query.css("[data-testid='selector-item-data_donation']"))
    |> click(Query.css("[data-testid='selector-item-data_donation']"))
    |> click(Query.css("[data-testid='create-item-button']"))

    # Verify assignment card appears
    session
    |> assert_has(Query.css(@card_selector, count: 1))
  end
end
