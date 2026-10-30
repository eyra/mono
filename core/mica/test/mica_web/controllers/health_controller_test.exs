defmodule MicaWeb.HealthControllerTest do
  use MicaWeb.ConnCase, async: true
  alias MicaWeb.HealthController

  describe "get" do
    test "ok", %{conn: conn} do
      conn = HealthController.get(conn, nil)
      assert text_response(conn, 200)
    end

    test "error", %{conn: conn} do
      # Return the database connection so the check query will fail.
      Ecto.Adapters.SQL.Sandbox.checkin(Mica.Repo)
      conn = HealthController.get(conn, nil)
      assert text_response(conn, 500)
    end
  end
end
