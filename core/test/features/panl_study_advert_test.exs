defmodule CoreWeb.Features.PanlStudyAdvertTest do
  @moduledoc """
  Feature test for creating a PaNL study (questionnaire assignment) and its advertisement.

  Tests the complete flow:
  1. Create a project
  2. Create a PaNL study (questionnaire) inside the project
  3. Navigate to the participants tab
  4. Create an advertisement for the study
  5. Publish the assignment
  6. Navigate to the advert and publish it
  7. Login as a PaNL participant and see the advert on home page
  """
  use CoreWeb.FeatureCase

  alias Systems.Pool

  @card_selector "[data-testid^='card_']"

  @sessions 2
  @tag :feature
  feature "researcher publishes PaNL study and participant sees advert", %{
    sessions: [researcher_session, participant_session]
  } do
    # Ensure PaNL pool exists (required for advert creation)
    panl_pool = Pool.Assembly.get_or_create_panl()

    researcher_password = Factories.valid_user_password()
    participant_password = Factories.valid_user_password()

    researcher =
      Factories.insert!(:member, %{
        password: researcher_password,
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        creator: true
      })

    participant =
      Factories.insert!(:member, %{
        password: participant_password,
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        creator: false
      })

    # Add participant to PaNL pool
    Pool.Public.add_participant!(panl_pool, participant)

    # === RESEARCHER SESSION ===

    # Login as researcher
    researcher_session
    |> visit("/user/signin?tab=creator")
    |> fill_in(Query.css("[data-testid='signin-email-input']"), with: researcher.email)
    |> fill_in(Query.css("[data-testid='signin-password-input']"), with: researcher_password)
    |> click(Query.css("[data-testid='signin-submit-button']"))

    # Create project
    researcher_session
    |> assert_has(Query.css("[data-testid='create-first-project-button']"))
    |> click(Query.css("[data-testid='create-first-project-button']"))

    # Navigate into the project
    researcher_session
    |> assert_has(Query.css(@card_selector, count: 1))
    |> click(Query.css(@card_selector))
    |> assert_has(Query.css("[data-phx-main].phx-connected"))

    # Create PaNL study (questionnaire assignment)
    researcher_session
    |> assert_has(Query.css("[data-testid='create-first-item-button']"))
    |> click(Query.css("[data-testid='create-first-item-button']"))
    |> assert_has(Query.css("[data-testid='selector-item-questionnaire']"))
    |> click(Query.css("[data-testid='selector-item-questionnaire']"))
    |> click(Query.css("[data-testid='create-item-button']"))

    # Open the assignment CMS
    researcher_session
    |> assert_has(Query.css(@card_selector, count: 1))
    |> click(Query.css(@card_selector))
    |> assert_has(Query.css("[data-phx-main].phx-connected"))

    # Navigate to participants tab
    researcher_session
    |> assert_has(Query.css("[data-testid='assignment-tab-participants']"))
    |> click(Query.css("[data-testid='assignment-tab-participants']"))
    |> assert_has(Query.css("[data-phx-main].phx-connected"))

    # For PaNL studies, subject_count is managed via the Payment tab (slot purchasing).
    # Set it directly in the DB so the advert flow has open spots.
    page_url = Wallaby.Browser.current_url(researcher_session)

    [_, assignment_id_str | _] =
      page_url |> URI.parse() |> Map.get(:path) |> String.split("/assignment/")

    assignment_id = assignment_id_str |> String.split("/") |> hd() |> String.to_integer()

    assignment = Systems.Assignment.Public.get!(assignment_id, [:info])

    assignment.info
    |> Ecto.Changeset.change(%{subject_count: 100})
    |> Core.Repo.update!()

    # Create advertisement
    researcher_session
    |> assert_has(Query.css("[data-testid='create-advert-button']"))
    |> click(Query.css("[data-testid='create-advert-button']"))
    |> assert_has(Query.css("[data-testid='goto-advert-button']"))

    # Publish the assignment. Wait for the retract-button to appear — it
    # replaces publish-button once status flips to :online, so its presence
    # is a stable signal that the publish-triggered DOM morphs have settled.
    researcher_session
    |> assert_has(Query.css("[data-testid='publish-button']"))
    |> click(Query.css("[data-testid='publish-button']"))
    |> assert_has(Query.css("[data-testid='retract-button']"))

    # Navigate to the advert. Wrapped in retry_stale to re-find the button
    # if its element reference is invalidated between find and action.
    retry_stale do
      researcher_session |> click(Query.css("[data-testid='goto-advert-button']"))
    end

    researcher_session
    |> assert_has(Query.css("[data-testid='advert-publish-button']"))

    # Publish the advert
    researcher_session
    |> assert_has(Query.css("[data-testid='advert-publish-button']"))
    |> click(Query.css("[data-testid='advert-publish-button']"))
    |> assert_has(Query.css("[data-phx-main].phx-connected"))

    # === PARTICIPANT SESSION ===

    # Login as PaNL participant
    participant_session
    |> visit("/user/signin")
    |> fill_in(Query.css("[data-testid='signin-email-input']"), with: participant.email)
    |> fill_in(Query.css("[data-testid='signin-password-input']"), with: participant_password)
    |> click(Query.css("[data-testid='signin-submit-button']"))

    # Verify participant is on home page and sees the advert
    participant_session
    |> assert_has(Query.css("[data-phx-main].phx-connected"))
    |> assert_has(Query.css(@card_selector))
  end
end
