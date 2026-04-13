defmodule CoreWeb.Features.EmailCaptureTest do
  @moduledoc """
  Feature test for the email capture flow on the finished screen.

  Tests the participant experience: after completing a questionnaire assignment,
  the participant sees an email capture form on the finished screen, submits
  their email, and sees a success message.
  """
  use CoreWeb.FeatureCase

  alias Systems.Pool
  alias Systems.Assignment
  alias Systems.Crew

  @tag :feature
  feature "participant sees email capture form and submits email", %{session: session} do
    _panl_pool = Pool.Assembly.get_or_create_panl()

    password = Factories.valid_user_password()

    participant =
      Factories.insert!(:member, %{
        password: password,
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        creator: false
      })

    # Create a questionnaire assignment and complete it for the participant
    assignment = Assignment.Factories.create_questionnaire_assignment()
    assignment = Assignment.Factories.add_participant(assignment, participant)

    # Mark task as completed using the correct identifier format
    %{crew: crew, workflow: workflow} = assignment
    %{items: [item]} = workflow |> Repo.preload([:items])
    member = Crew.Public.get_member(crew, participant) |> Repo.preload([:user])
    identifier = Assignment.Private.task_identifier(assignment, item, member)
    Crew.Factories.create_task(crew, member, identifier, status: :completed)

    # Login as participant
    session
    |> visit("/user/signin")
    |> fill_in(Query.css("[data-testid='signin-email-input']"), with: participant.email)
    |> fill_in(Query.css("[data-testid='signin-password-input']"), with: password)
    |> click(Query.css("[data-testid='signin-submit-button']"))
    |> assert_has(Query.css("[data-phx-main].phx-connected"))

    # Navigate to the assignment — should show finished view
    session
    |> visit("/assignment/#{assignment.id}")
    |> assert_has(Query.css("[data-phx-main].phx-connected"))

    # Should see the email capture form
    session
    |> assert_has(Query.css("[data-testid='email-capture-block']"))
    |> assert_has(Query.css("[data-testid='email-capture-input']"))
    |> assert_has(Query.css("[data-testid='email-capture-submit']"))

    # Submit email
    new_email = "panl-capture-#{System.unique_integer([:positive])}@example.com"

    session
    |> fill_in(Query.css("[data-testid='email-capture-input']"), with: new_email)
    |> click(Query.css("[data-testid='email-capture-submit']"))

    # Should see success state
    session
    |> assert_has(Query.css("[data-testid='email-capture-success']"))
  end
end
