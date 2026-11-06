defmodule NextWeb.Features.EmailCaptureTest do
  @moduledoc """
  Feature test for the pre-launch email capture flow on the finished screen.

  Tests the participant experience: an affiliate participant who completed a
  questionnaire assignment sees an email capture form on the finished screen,
  submits their email, and sees the submitted state.
  """
  use MicaWeb.FeatureCase
  use Mica.FeatureFlags.Test

  alias Systems.Account
  alias Systems.Affiliate
  alias Systems.Assignment
  alias Systems.Pool

  setup do
    set_feature_flag(:panl, true)
    set_feature_flag(:panl_post_launch, false)
    :ok
  end

  @tag :feature
  feature "participant sees email capture form and submits email", %{session: session} do
    _panl_pool = Pool.Assembly.get_or_create_panl()

    affiliate = Factories.insert!(:affiliate)
    assignment = Assignment.Factories.create_questionnaire_assignment(%{affiliate: affiliate})
    %{user: participant} = Affiliate.Public.obtain_user!("test_participant", affiliate)

    assignment
    |> Assignment.Factories.add_participant(participant)
    |> Assignment.Factories.finish_all_tasks(participant)

    new_email = "panl-capture-#{System.unique_integer([:positive])}@example.com"

    session
    |> visit_affiliate_link(assignment, "test_participant")
    |> assert_connected("[data-testid='email-capture-input']")
    |> fill_in(Query.css("[data-testid='email-capture-input']"), with: new_email)
    |> click(Query.css("[data-testid='email-capture-submit']"))
    |> assert_has(
      Query.css(
        "[data-testid='email-capture-block']:not(:has([data-testid='email-capture-input']))"
      )
    )

    assert %{email: ^new_email} = Account.Public.get!(participant.id)
    assert Pool.Public.participant?(:panl, participant)
  end
end
