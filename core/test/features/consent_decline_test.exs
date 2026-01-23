defmodule CoreWeb.Features.ConsentDeclineTest do
  @moduledoc """
  Integration test for consent decline flow.

  Reproduces bug #9496247794: declining consent causes crash in logs
  """
  use CoreWeb.FeatureCase

  alias Systems.Assignment
  alias Systems.Affiliate

  defp visit_assignment(session, assignment) do
    sqid = Affiliate.Sqids.encode!([0, assignment.id])
    affiliate_url = "/a/#{sqid}?p=test_participant_#{:rand.uniform(100_000)}"

    session
    |> visit(affiliate_url)
    |> assert_has(Query.css("[id='crew_page']"))
  end

  defp decline_consent(session) do
    session
    |> click(Query.css("[phx-click='decline']"))
  end

  @tag :feature
  feature "declining consent shows message without crash", %{session: session} do
    assignment = Assignment.Factories.create_assignment_with_consent_and_affiliate()

    session
    |> visit_assignment(assignment)
    |> decline_consent()
    |> assert_has(Query.text("Consent Declined"))
    |> assert_has(Query.text("You chose not to participate"))
    |> assert_has(Query.text("You can now close this window"))
  end

  @tag :feature
  feature "declining consent with redirect shows continue button", %{session: session} do
    redirect_url = "https://example.com/return"
    assignment = Assignment.Factories.create_assignment_with_consent_and_affiliate(redirect_url)

    session
    |> visit_assignment(assignment)
    |> decline_consent()
    |> assert_has(Query.text("Consent Declined"))
    |> assert_has(Query.text("Click Continue to proceed"))
    |> assert_has(Query.css("a[href*='example.com']"))
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
    |> assert_has(Query.text("Consent Declined"))
    |> assert_has(Query.text("Research Panel"))
    |> assert_has(Query.text("Click Continue to proceed to Research Panel"))
  end

  @tag :feature
  feature "back button on finished screen returns to consent page", %{session: session} do
    assignment = Assignment.Factories.create_assignment_with_consent_and_affiliate()

    session
    |> visit_assignment(assignment)
    |> decline_consent()
    |> assert_has(Query.text("Consent Declined"))
    # Click the back button
    |> click(Query.css("[phx-click='retry']"))
    # Should return to consent page
    |> assert_has(Query.text("Consent"))
    |> assert_has(Query.css("[phx-click='decline']"))
  end
end
