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
      assignment = Factories.insert!(:assignment, %{datadonation_tool: data_donation_tool})
      campaign = Factories.insert!(:campaign, %{assignment: assignment})
      Authorization.assign_role(user, campaign, :owner)
      {:ok, _view, html} = live(conn, Routes.live_path(conn, Dashboard))

      assert html =~ campaign.promotion.title
    end
  end
end
