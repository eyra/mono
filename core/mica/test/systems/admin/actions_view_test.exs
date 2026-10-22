defmodule Systems.Admin.ActionsViewTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias Systems.Admin

  describe "ActionsView" do
    test "renders actions view with all sections", %{conn: conn} do
      conn = conn |> Map.put(:request_path, "/admin/actions")

      session = %{}

      {:ok, view, html} = live_isolated(conn, Admin.ActionsView, session: session)

      # Should render actions view
      assert view |> has_element?("[data-testid='actions-view']")

      # Should show title
      assert view |> has_element?("[data-testid='actions-title']")
      assert html =~ "Actions"

      # Should render all three sections
      assert view |> has_element?("[data-testid='section-0']")
      assert view |> has_element?("[data-testid='section-1']")
      assert view |> has_element?("[data-testid='section-2']")

      # Should show section titles
      assert html =~ "Book keeping &amp; Finance"
      assert html =~ "Assignments"
      assert html =~ "Monitoring"
    end

    test "renders rollback expired deposits button", %{conn: conn} do
      conn = conn |> Map.put(:request_path, "/admin/actions")

      session = %{}

      {:ok, _view, html} = live_isolated(conn, Admin.ActionsView, session: session)

      # Should show rollback button
      assert html =~ "Rollback expired deposits"
    end

    test "renders expire tasks button", %{conn: conn} do
      conn = conn |> Map.put(:request_path, "/admin/actions")

      session = %{}

      {:ok, _view, html} = live_isolated(conn, Admin.ActionsView, session: session)

      # Should show expire button
      assert html =~ "Mark expired tasks"
    end

    test "renders crash button in monitoring section", %{conn: conn} do
      conn = conn |> Map.put(:request_path, "/admin/actions")

      session = %{}

      {:ok, _view, html} = live_isolated(conn, Admin.ActionsView, session: session)

      # Should show crash button
      assert html =~ "Raise a test exception"
    end

    test "expire event is handled", %{conn: conn} do
      conn = conn |> Map.put(:request_path, "/admin/actions")

      session = %{}

      {:ok, view, _html} = live_isolated(conn, Admin.ActionsView, session: session)

      # Click expire button and verify no crash
      view |> render_click("expire")

      # View should still be rendered
      assert view |> has_element?("[data-testid='actions-view']")
    end

    test "rollback_expired_deposits event is handled", %{conn: conn} do
      conn = conn |> Map.put(:request_path, "/admin/actions")

      session = %{}

      {:ok, view, _html} = live_isolated(conn, Admin.ActionsView, session: session)

      # Click rollback button and verify no crash
      view |> render_click("rollback_expired_deposits")

      # View should still be rendered
      assert view |> has_element?("[data-testid='actions-view']")
    end

    # Note: The crash button intentionally raises an exception for testing purposes.
    # We don't test it here as it creates noisy error logs.
  end
end
