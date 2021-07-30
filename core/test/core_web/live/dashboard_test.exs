defmodule CoreWeb.Live.DashboardTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  alias CoreWeb.Dashboard
  alias Core.Authorization

  describe "show the dashboard" do
    setup [:login_as_researcher]

    test "show the researchers content", %{conn: conn, user: user} do
      data_donation_tool = Factories.insert!(:data_donation_tool)
      Authorization.assign_role(user, data_donation_tool.study, :owner)
      {:ok, _view, html} = live(conn, Routes.live_path(conn, Dashboard))

      assert html =~ data_donation_tool.promotion.title
    end
  end
end
