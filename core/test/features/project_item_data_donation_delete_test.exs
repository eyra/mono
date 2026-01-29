defmodule CoreWeb.Features.ProjectItemDataDonationDeleteTest do
  @moduledoc """
  Feature test for deleting a data donation project item.

  Tests that after deletion, affiliate URL returns 404.

  Issue: #9511260407
  """
  use CoreWeb.FeatureCase

  # CSS selector for main cards (action buttons use {event}__action__card_{id} pattern)
  @card_selector "[data-testid^='card_']"

  @sessions 2
  @tag :feature
  feature "deleted assignment returns 404 for affiliate URL", %{
    sessions: [researcher, participant]
  } do
    password = Factories.valid_user_password()

    researcher_user =
      Factories.insert!(:member, %{
        password: password,
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        creator: true
      })

    # Step 1: Researcher logs in - use tab=creator param to avoid JS tab switching race conditions
    researcher
    |> visit("/user/signin?tab=creator")
    |> fill_in(Query.css("[data-testid='signin-email-input']"), with: researcher_user.email)
    |> fill_in(Query.css("[data-testid='signin-password-input']"), with: password)
    |> click(Query.css("[data-testid='signin-submit-button']"))

    # Step 2: Create project
    researcher
    |> assert_has(Query.css("[data-testid='create-first-project-button']"))
    |> click(Query.css("[data-testid='create-first-project-button']"))

    researcher
    |> assert_has(Query.css(@card_selector, count: 1))
    |> click(Query.css(@card_selector))

    # Step 3: Create assignment
    researcher
    |> assert_has(Query.css("[data-testid='create-first-item-button']"))
    |> click(Query.css("[data-testid='create-first-item-button']"))
    |> assert_has(Query.css("[data-testid='selector-item-data_donation']"))
    |> click(Query.css("[data-testid='selector-item-data_donation']"))
    |> click(Query.css("[data-testid='create-item-button']"))

    # Step 4: Navigate to assignment and get affiliate URL
    researcher
    |> assert_has(Query.css(@card_selector, count: 1))
    |> click(Query.css(@card_selector))
    |> assert_has(Query.css("[data-testid='assignment-tab-participants']"))
    |> click(Query.css("[data-testid='assignment-tab-participants']"))
    |> assert_has(Query.css("[data-testid='copy-affiliate-url-button']"))

    affiliate_url =
      researcher
      |> find(Query.css("[data-testid='copy-affiliate-url-button']"))
      |> Wallaby.Element.attr("data-text")

    # Step 5: Publish the assignment
    researcher
    |> click(Query.css("[data-testid='publish-button']"))
    |> assert_has(Query.css("[data-testid='retract-button']"))

    # Step 6: Participant visits the affiliate URL
    participant_url = affiliate_url |> String.replace("participant_id", "test_participant_456")

    participant
    |> visit(participant_url)
    |> assert_has(Query.css("[id='crew_page']"))

    # Step 7: Researcher navigates back to project and deletes the assignment
    # First navigate to project list and click into the project node
    researcher
    |> visit("/project")
    |> assert_has(Query.css(@card_selector, count: 1))
    |> click(Query.css(@card_selector))

    # Wait for LiveView to be fully connected (phx-connected class is added when WebSocket is ready)
    # This prevents stale reference errors from interacting with elements during DOM morphing
    researcher
    |> assert_has(Query.css("[data-phx-main].phx-connected"))
    |> assert_has(Query.css("[data-testid^='show_more__action__card_']"))

    # Click show_more to reveal actions, then delete
    researcher
    |> click(Query.css("[data-testid^='show_more__action__card_']"))
    |> click(Query.css("[data-testid^='delete__action__card_']"))

    # Wait for the card to be removed - project should now show empty state
    researcher
    |> assert_has(Query.css("[data-testid='create-first-item-button']"))

    # Step 8: Participant tries to access the affiliate URL again - should get 404
    participant
    |> visit(participant_url)
    |> assert_has(Query.css("[data-testid='error-404']"))
  end
end
