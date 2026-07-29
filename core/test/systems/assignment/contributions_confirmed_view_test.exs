defmodule Systems.Assignment.ContributionsConfirmedViewTest do
  use Core.DataCase

  import Phoenix.LiveViewTest

  alias Core.Factories
  alias Systems.Assignment
  alias Systems.Assignment.ContributionsTestHelper

  setup do
    {:ok, ContributionsTestHelper.setup_assignment_with_member()}
  end

  defp render_view(assignment) do
    render_component(Assignment.ContributionsConfirmedView,
      id: "contributions-confirmed",
      assignment: assignment
    )
  end

  test "renders the confirmed section container", %{assignment: assignment} do
    assert render_view(assignment) =~ ~s(data-testid="contributions-confirmed")
  end

  test "renders zero-count and empty message when there are no confirmed contributions",
       %{assignment: assignment} do
    html = render_view(assignment)

    assert html =~ ~s(data-testid="contributions-confirmed-count")
    assert html =~ ~s(data-testid="contributions-confirmed-empty")
    refute html =~ ~s(data-testid=\"contributions-confirmed-row-)
  end

  test "renders one row per paid reward", %{assignment: assignment, user: user, fund: fund} do
    r1 =
      Factories.insert!(:reward, %{
        idempotence_key: "rw-paid-1-#{System.unique_integer([:positive])}",
        amount: 500,
        status: :paid,
        user: user,
        fund: fund
      })

    r2 =
      Factories.insert!(:reward, %{
        idempotence_key: "rw-paid-2-#{System.unique_integer([:positive])}",
        amount: 700,
        status: :paid,
        user: user,
        fund: fund
      })

    html = render_view(assignment)

    assert html =~ ~s(data-testid="contributions-confirmed-row-#{r1.id}")
    assert html =~ ~s(data-testid="contributions-confirmed-row-#{r2.id}")
    refute html =~ ~s(data-testid="contributions-confirmed-empty")
  end
end
