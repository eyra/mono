defmodule Systems.Assignment.ContributionsPendingViewTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias Systems.Assignment.ContributionsPendingView

  defp render_view(rows) do
    render_component(ContributionsPendingView,
      id: "contributions-pending",
      rows: rows,
      count: length(rows)
    )
  end

  defp row(overrides \\ %{}) do
    Map.merge(
      %{
        reward_id: 1,
        user_id: 100,
        member_public_id: 1,
        completed_task_count: 1,
        total_task_count: 1
      },
      overrides
    )
  end

  test "renders the pending section container" do
    assert render_view([]) =~ ~s(data-testid="contributions-pending")
  end

  test "renders the empty state and hides the confirm button when count is 0" do
    html = render_view([])

    assert html =~ ~s(data-testid="contributions-pending-empty")
    refute html =~ ~s(data-testid="confirm-all-button")
  end

  test "renders one row per pending contribution" do
    html = render_view([row(%{reward_id: 42})])

    refute html =~ ~s(data-testid="contributions-pending-empty")
    assert html =~ ~s(data-testid="pending-row-42")
  end

  test "renders the confirm-all button when count > 0" do
    assert render_view([row()]) =~ ~s(data-testid="confirm-all-button")
  end

  test "styles the tasks label as warning when not all tasks are finished" do
    html = render_view([row(%{reward_id: 7, completed_task_count: 1, total_task_count: 3})])

    assert html =~ ~s(text-warning)
    assert html =~ ~s(data-testid="tasks-finished-7")
  end
end
