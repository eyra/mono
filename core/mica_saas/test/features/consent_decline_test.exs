defmodule MicaWeb.Features.ConsentDeclineTest do
  @moduledoc """
  Integration test for consent decline flow.

  Reproduces bug #9496247794: declining consent causes crash in logs
  """
  use MicaWeb.FeatureCase
  use Gettext, backend: MicaWeb.Gettext

  alias Systems.Assignment

  @decline_button "[data-testid='consent-decline-button']"
  @finished_title "[data-testid='finished-title']"
  @finished_body "[data-testid='finished-body']"

  defp visit_assignment(session, assignment) do
    session
    |> visit_affiliate_link(assignment, "test_participant_#{:rand.uniform(100_000)}")
    |> assert_connected(@decline_button)
  end

  defp decline_consent(session) do
    session
    |> click(Query.css(@decline_button))
    |> assert_has(
      Query.css(@finished_title,
        text: dgettext("eyra-assignment", "finished_view.title.declined")
      )
    )
  end

  @tag :feature
  feature "declining consent shows message without crash", %{session: session} do
    assignment = Assignment.Factories.create_assignment_with_consent_and_affiliate()

    session
    |> visit_assignment(assignment)
    |> decline_consent()
    |> assert_has(
      Query.css(@finished_body, text: dgettext("eyra-assignment", "finished_view.body.declined"))
    )
    |> refute_has(Query.css("[data-testid='continue-button']"))
  end

  @tag :feature
  feature "declining consent with redirect shows continue button", %{session: session} do
    redirect_url = "https://example.com/return"
    assignment = Assignment.Factories.create_assignment_with_consent_and_affiliate(redirect_url)

    session
    |> visit_assignment(assignment)
    |> decline_consent()
    |> assert_has(
      Query.css(@finished_body,
        text: dgettext("eyra-assignment", "finished_view.body.declined.redirect")
      )
    )
    |> assert_has(Query.css("[data-testid='continue-button'][href*='example.com']"))
  end

  @tag :feature
  feature "declining consent with platform name shows platform in message", %{session: session} do
    redirect_url = "https://research-panel.com/return"
    platform_name = "Research Panel"

    assignment =
      Assignment.Factories.create_assignment_with_consent_and_affiliate(
        redirect_url,
        platform_name
      )

    session
    |> visit_assignment(assignment)
    |> decline_consent()
    |> assert_has(
      Query.css(@finished_body,
        text:
          dgettext("eyra-assignment", "finished_view.body.declined.redirect.platform",
            platform: platform_name
          )
      )
    )
  end

  @tag :feature
  feature "back button on finished screen returns to consent page", %{session: session} do
    assignment = Assignment.Factories.create_assignment_with_consent_and_affiliate()

    session
    |> visit_assignment(assignment)
    |> decline_consent()
    |> click(Query.css("[data-testid='back-button']"))
    |> assert_has(Query.css(@decline_button))
    |> refute_has(Query.css(@finished_title))
  end
end
