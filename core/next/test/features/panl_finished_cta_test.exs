defmodule CoreWeb.Features.PanlFinishedCTATest do
  @moduledoc """
  Feature test for the post-launch Panl block on the finished screen.

  Covers the two CTA variants seen by affiliate participants when
  `:panl_post_launch` is on:

    * Not yet a Panl member → "Join Panl" CTA that sends them into
      auth with `?return_to=/pool/panl/join`.
    * Already a Panl member → "Home" CTA that sends them to `/`.

  The auth flow that runs after the "Join Panl" click (identify →
  verify → redeem) is exercised at the unit level in
  `Next.Account.SessionControllerTest`. This test verifies the UI
  plumbing on the finished page — the right block state renders and
  the CTA points at the right destination.
  """
  use CoreWeb.FeatureCase
  use Core.FeatureFlags.Test

  alias Systems.Affiliate
  alias Systems.Assignment
  alias Systems.Pool

  @participant_id "test_participant"

  setup do
    set_feature_flag(:panl, true)
    set_feature_flag(:panl_post_launch, true)
    :ok
  end

  @tag :feature
  feature "affiliate who is not yet a Panl member sees a Join CTA and lands on auth identify",
          %{session: session} do
    _panl_pool = Pool.Assembly.get_or_create_panl()
    {_participant, assignment} = setup_affiliate_at_finished()

    session
    |> visit_finished(assignment)
    |> click(Query.css("[data-testid='panl-cta-button']"))
    |> assert_has(Query.css("[data-testid='auth-email-input']"))

    assert Wallaby.Browser.current_path(session) == "/user/auth/identify"

    return_to =
      session
      |> Wallaby.Browser.current_url()
      |> URI.parse()
      |> Map.get(:query, "")
      |> URI.decode_query()
      |> Map.get("return_to")

    assert return_to == "/pool/panl/join"
  end

  # Fails until affiliates stay signed in outside their assignment:
  # https://app.basecamp.com/5734045/buckets/35926565/todos/10415375277
  @tag :feature
  @tag :skip
  feature "affiliate who is already a Panl member sees a Home CTA and lands on the home page",
          %{session: session} do
    panl_pool = Pool.Assembly.get_or_create_panl()
    {participant, assignment} = setup_affiliate_at_finished()
    Pool.Public.add_participant!(panl_pool, participant)

    session
    |> visit_finished(assignment)
    |> click(Query.css("[data-testid='panl-cta-button']"))
    |> assert_has(Query.css("[data-testid='home-logged-in-view']"))

    assert Wallaby.Browser.current_path(session) == "/"
  end

  # Builds an affiliate participant of a questionnaire assignment with their
  # single task already completed, so the affiliate link lands on the
  # finished view.
  defp setup_affiliate_at_finished do
    affiliate = Factories.insert!(:affiliate)
    assignment = Assignment.Factories.create_questionnaire_assignment(%{affiliate: affiliate})
    %{user: participant} = Affiliate.Public.obtain_user!(@participant_id, affiliate)

    assignment
    |> Assignment.Factories.add_participant(participant)
    |> Assignment.Factories.finish_all_tasks(participant)

    {participant, assignment}
  end

  defp visit_finished(session, assignment) do
    session
    |> visit_affiliate_link(assignment, @participant_id)
    |> assert_has(Query.css("[data-testid='email-capture-block']"))
    |> assert_has(Query.css("[data-testid='panl-cta-button']"))
    |> refute_has(Query.css("[data-testid='email-capture-input']"))
  end
end
