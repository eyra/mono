defmodule LinkWeb.DashboardControllerTest do
  use LinkWeb.ConnCase

  alias Link.Factories

  setup %{conn: conn} do
    member = Factories.insert!(:member)
    conn = Pow.Plug.assign_current_user(conn, member, otp_app: :link_web)

    {:ok, conn: conn, member: member}
  end

  describe "index" do
    test "list all available studies", %{conn: conn} do
      titles = ["Analytical Engine", "FLOW-MATIC"]
      titles |> Enum.map(&Factories.insert!(:study, title: &1))
      conn = get(conn, Routes.static_path(@conn, "/dashboard"))

      for title <- titles do
        assert html_response(conn, 200) =~ title
      end
    end
  end
end
