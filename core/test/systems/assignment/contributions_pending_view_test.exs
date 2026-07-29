defmodule Systems.Assignment.ContributionsPendingViewTest do
  use Core.DataCase

  import Phoenix.LiveViewTest

  alias Systems.Assignment
  alias Systems.Assignment.ContributionsTestHelper
  alias Systems.Crew
  alias Systems.Fund

  setup do
    {:ok, ContributionsTestHelper.setup_assignment_with_member()}
  end

  defp render_view(assignment) do
    render_component(Assignment.ContributionsPendingView,
      id: "contributions-pending",
      assignment: assignment
    )
  end

  defp create_pending_contribution(assignment, user, crew, member) do
    idempotence_key = Assignment.Public.idempotence_key(assignment, user)
    {:ok, _} = Fund.Public.create_reward(assignment.fund, 1000, user, idempotence_key)
    {:ok, _} = Fund.Public.mark_pending_approval(idempotence_key)

    Crew.Factories.create_task(crew, member, ["task1", "member=#{member.id}"], status: :completed)

    Assignment.Public.get!(assignment.id, Assignment.Model.preload_graph(:down))
  end

  test "renders the pending section container", %{assignment: assignment} do
    assert render_view(assignment) =~ ~s(data-testid="contributions-pending")
  end

  test "renders the empty state and hides the confirm button when count is 0",
       %{assignment: assignment} do
    html = render_view(assignment)

    assert html =~ ~s(data-testid="contributions-pending-empty")
    refute html =~ ~s(data-testid="confirm-all-button")
  end

  test "renders one row per pending contribution",
       %{assignment: assignment, user: user, crew: crew, member: member} do
    assignment = create_pending_contribution(assignment, user, crew, member)

    html = render_view(assignment)

    refute html =~ ~s(data-testid="contributions-pending-empty")
    assert html =~ ~s(data-testid="payout-row-)
  end

  test "renders the confirm-all button when count > 0",
       %{assignment: assignment, user: user, crew: crew, member: member} do
    assignment = create_pending_contribution(assignment, user, crew, member)

    assert render_view(assignment) =~ ~s(data-testid="confirm-all-button")
  end
end
