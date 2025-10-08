defmodule CoreWeb.Live.MobileMenuTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  describe "mobile menu with Phoenix.JS implementation" do
    setup [:login_as_member]

    test "mobile menu HTML structure is correct", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      # Check that mobile menu div exists with correct ID and hidden class
      assert html =~ ~r/id="mobile-menu"/
      assert html =~ ~r/id="mobile-menu"[^>]*class="[^"]*hidden/

      # Check that backdrop div exists with correct ID and hidden class
      assert html =~ ~r/id="mobile-menu-backdrop"/
      assert html =~ ~r/id="mobile-menu-backdrop"[^>]*class="[^"]*hidden/
    end

    test "menu button has Phoenix.JS commands", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html = render(view)

      # Check that there's a button with Phoenix.JS toggle commands
      # The phx-click should have JS commands to toggle both menu and backdrop
      assert html =~ ~r/phx-click=.*toggle.*#mobile-menu/
      assert html =~ ~r/phx-click=.*toggle.*#mobile-menu-backdrop/

      # Verify the exact JS command structure (escaped JSON)
      assert html =~ "[[&quot;toggle&quot;,{&quot;to&quot;:&quot;#mobile-menu&quot;}]"
    end

    test "backdrop has Phoenix.JS hide commands", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html = render(view)

      # Check that backdrop has phx-click to hide both menu and backdrop
      assert html =~ ~r/id="mobile-menu-backdrop"[^>]*phx-click/

      # The backdrop click should hide both elements
      assert html =~ ~r/phx-click=.*\[\[.*hide.*#mobile-menu.*\]\]/
      assert html =~ ~r/phx-click=.*\[\[.*hide.*#mobile-menu-backdrop.*\]\]/
    end

    test "mobile menu uses Phoenix.JS for toggle", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html = render(view)

      # Verify that the mobile menu uses Phoenix.JS exclusively
      refute html =~ "mobile_menu = !mobile_menu"
      refute html =~ "x-data"
      refute html =~ "x-show"
      refute html =~ "@click"

      # The mobile menu should use Phoenix.JS commands
      assert html =~ "id=\"mobile-menu\""
      assert html =~ "id=\"mobile-menu-backdrop\""
      assert html =~ ~r/phx-click=.*toggle.*#mobile-menu/
    end

    test "menu structure contains navigation items", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html = render(view)

      # Check that the mobile menu contains expected navigation structure
      assert html =~ ~r/id="mobile-menu".*mobile_menu_profile/s
      assert html =~ ~r/id="mobile-menu".*\/user\/profile/s
    end
  end
end
