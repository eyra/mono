defmodule Systems.Assignment.ContributionsDeclinedViewTest do
  use Core.DataCase

  import Phoenix.LiveViewTest

  alias Core.Factories
  alias Systems.Assignment
  alias Systems.Assignment.ContributionsTestHelper

  setup do
    {:ok, ContributionsTestHelper.setup_assignment_with_member()}
  end

  defp render_view(assignment) do
    render_component(Assignment.ContributionsDeclinedView,
      id: "contributions-declined",
      assignment: assignment
    )
  end

  defp insert_rejected(user, fund, amount \\ 500) do
    Factories.insert!(:reward, %{
      idempotence_key: "rw-rejected-#{System.unique_integer([:positive])}",
      amount: amount,
      status: :rejected,
      rejected_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      user: user,
      fund: fund
    })
  end

  test "renders the declined section container", %{assignment: assignment, user: user, fund: fund} do
    insert_rejected(user, fund)
    assert render_view(assignment) =~ ~s(data-testid="contributions-declined")
  end

  test "renders a count matching the number of declined rewards",
       %{assignment: assignment, user: user, fund: fund} do
    insert_rejected(user, fund)
    insert_rejected(user, fund)

    html = render_view(assignment)

    count =
      html
      |> Floki.parse_fragment!()
      |> Floki.find(~s([data-testid="contributions-declined-count"]))
      |> Floki.text()
      |> String.trim()

    assert count == "2"
  end

  test "renders one row per declined reward",
       %{assignment: assignment, user: user, fund: fund} do
    r1 = insert_rejected(user, fund, 500)
    r2 = insert_rejected(user, fund, 800)

    html = render_view(assignment)

    assert html =~ ~s(data-testid="contributions-declined-row-#{r1.id}")
    assert html =~ ~s(data-testid="contributions-declined-row-#{r2.id}")
  end
end
