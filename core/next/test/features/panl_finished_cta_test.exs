defmodule CoreWeb.Features.PanlFinishedCTATest do
  @moduledoc """
  Feature test for the post-launch Panl block on the finished screen.

  Covers the two CTA variants seen by affiliate participants when
  `:panl_post_launch` is on:

    * Not yet a Panl member → "Join Panl" CTA that sends them into
      auth with `?return_to=/pool/panl/join`.
    * Already a Panl member → "Home" CTA that sends them to `/`.

  The auth flow that runs after the "Join Panl" click (identify →
  verify → redeem → affiliate-linking) is exercised at the unit level
  in `Next.Account.SessionControllerTest`. This test verifies the UI
  plumbing on the finished page — the right block state renders and
  the CTA points at the right destination.
  """
  use CoreWeb.FeatureCase
  use Core.FeatureFlags.Test

  alias Systems.Pool
  alias Systems.Assignment
  alias Systems.Crew

  setup do
    set_feature_flag(:panl, true)
    set_feature_flag(:panl_post_launch, true)
    :ok
  end

  # Reaching the finished view from `visit/1` requires navigating the
  # `CrewPage` machinery (intro → consent → activate → tasks) which the
  # existing `email_capture_test` also punts on (marked `@tag :skip`).
  # State-machine coverage lives in `Systems.Assignment.FinishedViewBuilderTest`
  # and `Systems.Assignment.FinishedViewTest`; controller-linking coverage
  # in `Next.Account.SessionControllerTest`. Unskip this once a shared
  # helper for "drive a participant to the finished view" exists.
  @tag :feature
  @tag :skip
  feature "affiliate who is not yet a Panl member sees a Join CTA and lands on auth identify",
          %{session: session} do
    _panl_pool = Pool.Assembly.get_or_create_panl()
    {participant, password, assignment} = setup_affiliate_at_finished()

    session
    |> sign_in(participant, password)
    |> visit_finished(assignment)
    |> click(Query.css("[data-testid='panl-cta-button']"))
    |> assert_path_changed_from("/assignment/#{assignment.id}")
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

  @tag :feature
  @tag :skip
  feature "affiliate who is already a Panl member sees a Home CTA and lands on the home page",
          %{session: session} do
    panl_pool = Pool.Assembly.get_or_create_panl()
    {participant, password, assignment} = setup_affiliate_at_finished()
    Pool.Public.add_participant!(panl_pool, participant)

    session
    |> sign_in(participant, password)
    |> visit_finished(assignment)
    |> click(Query.css("[data-testid='panl-cta-button']"))
    |> assert_path_changed_from("/assignment/#{assignment.id}")
    |> assert_has(Query.css("[data-testid='home-page']"))

    assert Wallaby.Browser.current_path(session) == "/"
  end

  # Builds a confirmed affiliate participant + a questionnaire assignment
  # with the participant's single task pre-completed, so hitting
  # `/assignment/:id` should route straight to the finished view.
  defp setup_affiliate_at_finished do
    password = Factories.valid_user_password()

    participant =
      Factories.insert!(:member, %{
        password: password,
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        creator: false
      })

    assignment =
      Assignment.Factories.create_questionnaire_assignment()
      |> Assignment.Factories.add_participant(participant)

    Factories.insert!(:affiliate_user, %{user: participant, identifier: "test_participant"})

    mark_assignment_finished(assignment, participant)

    {participant, password, assignment}
  end

  defp visit_finished(session, assignment) do
    session
    |> visit("/assignment/#{assignment.id}")
    |> assert_has(Query.css("[data-testid='email-capture-block']"))
    |> assert_has(Query.css("[data-testid='panl-cta-button']"))
    |> refute_has(Query.css("[data-testid='email-capture-input']"))
  end

  defp mark_assignment_finished(assignment, participant) do
    %{crew: crew, workflow: workflow} = assignment
    %{items: [item]} = workflow |> Repo.preload([:items])
    member = Crew.Public.get_member(crew, participant) |> Repo.preload([:user])
    identifier = Assignment.Private.task_identifier(assignment, item, member)
    Crew.Factories.create_task(crew, member, identifier, status: :completed)
  end
end
