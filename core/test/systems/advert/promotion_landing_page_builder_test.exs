defmodule Systems.Advert.PromotionLandingPageBuilderTest do
  use CoreWeb.ConnCase, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  import ExUnit.Assertions

  alias Systems.Advert
  alias Systems.Pool

  describe "Promotion Landing Page" do
    setup [:login_as_member]

    test "Render", %{conn: conn} do
      creator = Factories.insert!(:creator)
      %{promotion: %{id: promotion_id}} = Advert.Factories.create_advert(creator, :accepted, 1)
      {:ok, _view, html} = live(conn, ~p"/promotion/#{promotion_id}")
      assert html =~ "Participate"
    end

    test "Participate", %{conn: %{assigns: %{current_user: participant}} = conn} do
      creator = Factories.insert!(:creator)

      %{promotion_id: promotion_id, submission_id: submission_id, assignment_id: assignment_id} =
        Advert.Factories.create_advert(creator, :accepted, 1)

      {:ok, view, _html} = live(conn, ~p"/promotion/#{promotion_id}")

      view
      |> element("[phx-click=\"call-to-action-1\"]")
      |> render_click()

      assert_redirected(view, "/assignment/#{assignment_id}/apply")
      assert Pool.Public.participant?(Pool.Public.get_by_submission!(submission_id), participant)
    end
  end
end
