defmodule NativeDemoWeb.ScreenLiveTest do
  use NativeDemoWeb.ConnCase

  import Phoenix.LiveViewTest

  alias NativeDemo.Navigation

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp fixture(:screen) do
    {:ok, screen} = Navigation.create_screen(@create_attrs)
    screen
  end

  defp create_screen(_) do
    screen = fixture(:screen)
    %{screen: screen}
  end

  describe "Index" do
    setup [:create_screen]

    test "lists all screens", %{conn: conn, screen: screen} do
      {:ok, _index_live, html} = live(conn, Routes.screen_index_path(conn, :index))

      assert html =~ "Listing Screens"
    end

    test "saves new screen", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.screen_index_path(conn, :index))

      assert index_live |> element("a", "New Screen") |> render_click() =~
               "New Screen"

      assert_patch(index_live, Routes.screen_index_path(conn, :new))

      assert index_live
             |> form("#screen-form", screen: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#screen-form", screen: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.screen_index_path(conn, :index))

      assert html =~ "Screen created successfully"
    end

    test "updates screen in listing", %{conn: conn, screen: screen} do
      {:ok, index_live, _html} = live(conn, Routes.screen_index_path(conn, :index))

      assert index_live |> element("#screen-#{screen.id} a", "Edit") |> render_click() =~
               "Edit Screen"

      assert_patch(index_live, Routes.screen_index_path(conn, :edit, screen))

      assert index_live
             |> form("#screen-form", screen: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#screen-form", screen: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.screen_index_path(conn, :index))

      assert html =~ "Screen updated successfully"
    end

    test "deletes screen in listing", %{conn: conn, screen: screen} do
      {:ok, index_live, _html} = live(conn, Routes.screen_index_path(conn, :index))

      assert index_live |> element("#screen-#{screen.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#screen-#{screen.id}")
    end
  end

  describe "Show" do
    setup [:create_screen]

    test "displays screen", %{conn: conn, screen: screen} do
      {:ok, _show_live, html} = live(conn, Routes.screen_show_path(conn, :show, screen))

      assert html =~ "Show Screen"
    end

    test "updates screen within modal", %{conn: conn, screen: screen} do
      {:ok, show_live, _html} = live(conn, Routes.screen_show_path(conn, :show, screen))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Screen"

      assert_patch(show_live, Routes.screen_show_path(conn, :edit, screen))

      assert show_live
             |> form("#screen-form", screen: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#screen-form", screen: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.screen_show_path(conn, :show, screen))

      assert html =~ "Screen updated successfully"
    end
  end
end
