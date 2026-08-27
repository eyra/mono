defmodule CoreWeb.Features.ApproveParticipationTest do
  @moduledoc """
  Researcher's Contributions-tab happy path: a completed contribution
  shows up in the Pending section; clicking "Confirm all" drains it.

  Setup runs the real `Assignment.Public.complete_participation/1` (not
  a Factory-set reward status) so the participation Multi + Switch signal
  chain that create the Pending row + PendingContributions NA are actually
  exercised. If either link breaks, the pending row wouldn't appear here
  and the assertion would fail.
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
  feature "researcher confirms a pending contribution from the Contributions tab",
          %{session: session} do
    password = Factories.valid_user_password()

    researcher =
      Factories.insert!(:member, %{
        password: password,
        confirmed_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
        verified_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
        creator: true
      })

    participant =
      Factories.insert!(:member, %{
        confirmed_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
        creator: false
      })

    # Assignment via the questionnaire factory (gives us crew + workflow +
    # workflow_item). Wrapped in project_item + project_node + project so
    # the LV's Project.LiveHook resolves a `branch` (otherwise
    # ContentPageBuilder.view_model/2 crashes calling `Concept.Branch.hierarchy(nil)`).
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

    assignment =
      Assignment.Model
      |> Core.Repo.get!(assignment.id)
      |> Core.Repo.preload(Assignment.Model.preload_graph(:down), force: true)

    # Researcher owns the assignment so they can see the Contributions tab.
    Factories.insert!(:role_assignment, %{
      node: assignment.auth_node,
      role: :owner,
      principal_id: researcher.id
    })

    [workflow_item | _] = assignment.workflow.items

    member = Crew.Factories.create_member(assignment.crew, participant)
    identifier = ["item=#{workflow_item.id}", "member=#{member.id}"]
    Crew.Factories.create_task(assignment.crew, member, identifier, status: :completed)

    Fund.Factories.create_reward(assignment, participant, fund)

    {:ok, participation} = Assignment.Public.obtain_participation(assignment, participant)
    {:ok, %{id: participation_id}} = Assignment.Public.complete_participation(participation)

    session
    |> visit("/user/signin?tab=creator")
    |> fill_in(Query.css("[data-testid='signin-email-input']"), with: researcher.email)
    |> fill_in(Query.css("[data-testid='signin-password-input']"), with: password)
    |> click(Query.css("[data-testid='signin-submit-button']"))
    |> assert_path_changed_from("/user/signin")
    |> visit("/assignment/#{assignment.id}/content?tab=contributions")
    |> assert_has(Query.css("[data-testid='contributions-view']"))
    |> assert_has(Query.css("[data-testid='pending-row-#{participation_id}']"))
    |> click(Query.css("[data-testid='confirm-all-button']"))
    |> assert_has(Query.css("[data-testid='contributions-pending-empty']"))
    |> assert_has(Query.css("[data-testid='contributions-confirmed-row-#{participation_id}']"))
  end
end
