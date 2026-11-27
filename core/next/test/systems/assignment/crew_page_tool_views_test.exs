defmodule Next.Systems.Assignment.CrewPageToolViewsTest do
  @moduledoc """
  A task on the crew page shows what its tool shows on its own page, for the tools of
  Next's systems. The crew task views give the tool view its tool without the tool's nested
  data. Mica's tools are in Self's suite.

  Zircon's screening tool view loads its own data from the tool's id, but it doesn't render
  yet, on the crew page nor on its own: `Zircon.Public.list_papers/1` reads papers it
  doesn't load.
  """
  use NextWeb.ConnCase, async: false
  use Gettext, backend: MicaWeb.Gettext
  import Phoenix.LiveViewTest
  import Systems.Assignment.CrewPageToolViewHelper

  alias Next.Systems.Graphite

  setup :login_as_member

  test "a Graphite task shows the leaderboard once submissions closed", %{conn: conn, user: user} do
    tool = Factories.insert!(:graphite_tool, %{deadline: ~U[2020-01-01 00:00:00Z]})
    leaderboard = Graphite.Factories.create_leaderboard(tool, %{status: :online})
    tool_ref = Graphite.Factories.create_tool_ref(tool, :submit)

    crew_task = open_crew_task(conn, tool_ref, user)

    assert crew_task == open_tool_view(conn, Graphite.ToolView, tool_ref, user)
    assert crew_task.text =~ dgettext("eyra-graphite", "leaderboard.goto.button")
    assert crew_task.links == ["/graphite/leaderboard/#{leaderboard.id}"]
  end

  defp open_crew_task(conn, tool_ref, user) do
    assignment = create_assignment(tool_ref, user)
    panel_info = %{panel: :affiliate, redirect_url: nil, participant: "participant-1"}

    {:ok, view, _html} =
      conn
      |> put_session(:panel_info, panel_info)
      |> live(~m"/assignment/#{assignment.id}")

    view |> render() |> crew_task_content()
  end

  defp open_tool_view(conn, tool_view, tool_ref, user) do
    conn = Map.put(conn, :request_path, "/tool")
    session = tool_view_session(tool_ref, user)

    {:ok, view, _html} = live_isolated(conn, tool_view, session: session)

    view |> render() |> tool_view_content()
  end
end
