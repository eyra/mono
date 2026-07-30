defmodule Systems.Assignment.ContributionsDeclinedViewTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias Systems.Assignment.ContributionsDeclinedView

  defp render_view(rows) do
    render_component(ContributionsDeclinedView,
      id: "contributions-declined",
      rows: rows,
      count: length(rows)
    )
  end

  defp row(reward_id, opts \\ []) do
    %{
      reward_id: reward_id,
      member_public_id: Keyword.get(opts, :member_public_id, reward_id),
      rejected_at: Keyword.get(opts, :rejected_at, ~N[2026-01-01 00:00:00]),
      rejection_reason: Keyword.get(opts, :rejection_reason, "not eligible")
    }
  end

  test "renders the declined section container" do
    assert render_view([row(1)]) =~ ~s(data-testid="contributions-declined")
  end

  test "renders a count matching the number of declined rewards" do
    html = render_view([row(1), row(2)])

    count =
      html
      |> Floki.parse_fragment!()
      |> Floki.find(~s([data-testid="contributions-declined-count"]))
      |> Floki.text()
      |> String.trim()

    assert count == "2"
  end

  test "renders one row per declined reward" do
    html = render_view([row(11), row(22)])

    assert html =~ ~s(data-testid="contributions-declined-row-11")
    assert html =~ ~s(data-testid="contributions-declined-row-22")
  end

  test "renders the rejection reason in the row" do
    html = render_view([row(9, rejection_reason: "duplicate submission")])

    assert html =~ ~s(data-testid="contributions-declined-reason-9")
    assert html =~ "duplicate submission"
  end
end
