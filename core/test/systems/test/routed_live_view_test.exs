defmodule Systems.Test.RoutedLiveViewTest do
  use CoreWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "basic rendering" do
    test "renders simple page", %{conn: conn} do
      {:ok, view, html} = live(conn, "/test/routed/simple")

      assert html =~ "Simple Test Page"
      assert view |> has_element?("[data-testid='routed-live-view']")
    end

    test "renders page with single child", %{conn: conn} do
      {:ok, view, html} = live(conn, "/test/routed/with_child")

      assert html =~ "Routed LiveView Test Page"
      assert view |> has_element?("[data-testid='routed-live-view']")
      assert view |> has_element?("[data-testid='embedded-view-child1']")
    end

    test "renders page with multiple children", %{conn: conn} do
      {:ok, view, html} = live(conn, "/test/routed/with_children")

      assert html =~ "Routed LiveView Test Page"
      assert view |> has_element?("[data-testid='embedded-view-child1']")
      assert view |> has_element?("[data-testid='embedded-view-child2']")
    end
  end

  describe "embedded view interaction" do
    test "embedded view renders items", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/test/routed/with_child")

      # Child 1 has items [10, 20, 30]
      assert view |> has_element?("[data-testid='item-10']")
      assert view |> has_element?("[data-testid='item-20']")
      assert view |> has_element?("[data-testid='item-30']")
    end

    test "multiple children render with their own items", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/test/routed/with_children")

      # Child 1 has items [10, 20, 30]
      assert view |> has_element?("[data-testid='item-10']")
      assert view |> has_element?("[data-testid='item-20']")
      assert view |> has_element?("[data-testid='item-30']")

      # Child 2 has items [40, 50]
      assert view |> has_element?("[data-testid='item-40']")
      assert view |> has_element?("[data-testid='item-50']")
    end
  end
end
