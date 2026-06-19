defmodule CoreWeb.Features.ApproveRewardTest do
  @moduledoc """
  Wallaby version of the Playwright `approve_reward.spec.ts` (UC-OPP-05).

  Verifies the researcher's PayoutModal flow: open from the
  pending-approvals banner → click "Pay out all" → the waiting list goes
  empty (reward leaves `:pending_approval`).

  The precondition state (funded assignment, participant with completed
  task, reward in `:pending_approval`) is built directly via Factories
  rather than walking the full signup-onboarding-advert-payment flow
  through the UI — UC-OPP-05 is about the approval interaction, not
  about how the reward got there. The Playwright version walked the
  whole chain because it ran against a deployed system; in Wallaby we
  can construct the state and stay focused on the LV that's actually
  under test.
  """

  use CoreWeb.FeatureCase

  alias Systems.Assignment
  alias Systems.Crew
  alias Systems.Fund
  alias Systems.Project

  setup do
    Factories.insert!(:currency_ledger, %{currency: :EUR})
    :ok
  end

  @tag :feature
  feature "researcher approves a participant reward via PayoutModal",
          %{session: session} do
    password = Factories.valid_user_password()

    researcher =
      Factories.insert!(:member, %{
        password: password,
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        creator: true
      })

    participant =
      Factories.insert!(:member, %{
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        creator: false
      })

    # Build the assignment via the existing questionnaire factory (gives us
    # crew + workflow + workflow_item). Then wrap it in a project_item +
    # project_node + project so the LV's Project.LiveHook can resolve a
    # `branch` (otherwise ContentPageBuilder.view_model/2 crashes when it
    # calls `Concept.Branch.hierarchy(nil)`).
    assignment = Assignment.Factories.create_questionnaire_assignment()

    assignment
    |> Project.Factories.build_item()
    |> Project.Factories.build_node()
    |> Project.Factories.build_project()
    |> Core.Repo.insert!()

    currency = Factories.insert!(:currency, %{name: "eur_test"})

    fund =
      Factories.insert!(:fund, %{
        name: "fund_#{assignment.id}",
        currency: currency
      })

    {:ok, _} =
      assignment
      |> Assignment.Model.changeset(fund)
      |> Core.Repo.update()

    assignment = Core.Repo.preload(assignment, [:crew, :workflow], force: true)

    # Make the researcher the owner of the assignment so they can navigate
    # to the participants tab.
    Factories.insert!(:role_assignment, %{
      node: assignment.auth_node,
      role: :owner,
      principal_id: researcher.id
    })

    # Participant joins the crew + completes the workflow item's task.
    # Identifier mirrors the `["item=N", "member=M"]` shape the production
    # task_identifier helper uses for questionnaire assignments — that's
    # the format the signal chain (Assignment.Private.member_id/1) reads
    # when "Pay out all" approves the reward.
    [workflow_item | _] =
      assignment.workflow |> Core.Repo.preload(:items) |> Map.fetch!(:items)

    member = Crew.Factories.create_member(assignment.crew, participant)
    identifier = ["item=#{workflow_item.id}", "member=#{member.id}"]

    Crew.Factories.create_task(assignment.crew, member, identifier, status: :completed)

    # Reward in :pending_approval — what UC-OPP-05 acts on.
    Fund.Factories.create_reward(assignment, participant, fund)
    |> Ecto.Changeset.change(%{status: :pending_approval})
    |> Core.Repo.update!()

    session
    |> visit("/user/signin?tab=creator")
    |> fill_in(Query.css("[data-testid='signin-email-input']"), with: researcher.email)
    |> fill_in(Query.css("[data-testid='signin-password-input']"), with: password)
    |> click(Query.css("[data-testid='signin-submit-button']"))
    |> visit("/assignment/#{assignment.id}/content?tab=participants")
    |> assert_has(Query.css("[data-testid='pending-approvals-cta']"))
    |> click(Query.css("[data-testid='pending-approvals-cta']"))
    |> assert_has(Query.css("[data-testid='payout-modal']"))
    |> assert_has(Query.css("[data-testid='pay-out-all-button']"))
    |> click(Query.css("[data-testid='pay-out-all-button']"))
    |> assert_has(Query.css("[data-testid='payout-empty']"))
  end
end
