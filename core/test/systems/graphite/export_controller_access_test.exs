defmodule Systems.Graphite.ExportControllerAccessTest do
  use CoreWeb.ConnCase, async: true

  alias Systems.Graphite

  describe "submissions" do
    setup :login_as_member

    test "denies a member without access to the leaderboard", %{conn: conn} do
      leaderboard = Graphite.Factories.create_leaderboard(%{})

      conn = get(conn, ~p"/graphite/#{leaderboard.id}/export/submissions")

      assert conn.status == 403
    end

    test "sends the csv to the leaderboard owner", %{conn: conn} do
      leaderboard = Graphite.Factories.create_leaderboard(%{})
      :ok = Core.Authorization.assign_role(conn.assigns.current_user, leaderboard, :owner)

      conn = get(conn, ~p"/graphite/#{leaderboard.id}/export/submissions")

      assert conn.status == 200
      assert [content_type] = get_resp_header(conn, "content-type")
      assert content_type =~ "text/csv"
    end
  end
end
