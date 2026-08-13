defmodule Systems.Assignment.ContributionsConfirmedViewTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias Systems.Assignment.ContributionsConfirmedView

  defp render_view(rows) do
    render_component(ContributionsConfirmedView,
      id: "contributions-confirmed",
      rows: rows,
      count: length(rows)
    )
  end

  defp row(participation_id, member_public_id \\ nil) do
    %{participation_id: participation_id, member_public_id: member_public_id || participation_id}
  end

  test "renders the confirmed section container" do
    assert render_view([]) =~ ~s(data-testid="contributions-confirmed")
  end

  test "renders zero-count and empty message when there are no confirmed contributions" do
    html = render_view([])

    assert html =~ ~s(data-testid="contributions-confirmed-count")
    assert html =~ ~s(data-testid="contributions-confirmed-empty")
    refute html =~ ~s(data-testid="contributions-confirmed-row-)
  end

  test "renders one row per confirmed reward" do
    html = render_view([row(11), row(22)])

    assert html =~ ~s(data-testid="contributions-confirmed-row-11")
    assert html =~ ~s(data-testid="contributions-confirmed-row-22")
    refute html =~ ~s(data-testid="contributions-confirmed-empty")
  end
end
