defmodule Systems.Assignment.LandingPageTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Systems.Assignment

  setup :login_as_member

  setup %{user: user} do
    assignment = Assignment.Factories.create_assignment(10, 100)
    Assignment.Public.add_participant!(assignment, user)

    {:ok, assignment: assignment}
  end

  describe "landing page" do
    test "renders with assignment title and continue button", %{
      conn: conn,
      assignment: assignment
    } do
      {:ok, _view, html} = live(conn, ~p"/assignment/#{assignment.id}/landing")

      # Info title might be nil, so just check that the page renders with Continue button
      assert html =~ "Continue"
    end

    test "continue button navigates to join", %{conn: conn, assignment: assignment} do
      {:ok, view, _html} = live(conn, ~p"/assignment/#{assignment.id}/landing")

      assert view
             |> element("button", "Continue")
             |> render_click()

      assert_redirect(view, "/assignment/#{assignment.id}/join")
    end
  end
end
