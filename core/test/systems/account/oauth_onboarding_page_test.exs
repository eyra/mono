defmodule Systems.Account.OAuthOnboardingPageTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  setup %{conn: conn} do
    isolate_signals()

    user = Factories.insert!(:creator)
    {:ok, conn: conn, user: _user} = login(user, %{conn: conn})

    %{conn: conn, user: user}
  end

  describe "rendering" do
    test "renders welcome title and terms checkbox", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/user/oauth/onboarding")
      assert html =~ "Welcome"
      assert html =~ "Terms"
      assert html =~ "Privacy"
      assert html =~ "Continue"
    end
  end

  describe "toggle_terms event" do
    test "toggles the accepted state", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/user/oauth/onboarding")

      # Initially unaccepted - clicking continue flashes error
      assert view |> render_click("continue") =~ "Please accept"

      # Toggle to accepted
      view |> render_click("toggle_terms")
      # Continue now navigates away
      assert {:error, {:live_redirect, %{to: "/project"}}} =
               view |> render_click("continue")
    end
  end

  describe "continue event" do
    test "flashes error when terms not accepted", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/user/oauth/onboarding")
      assert view |> render_click("continue") =~ "Please accept"
    end

    test "redirects creator to /project when terms accepted", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/user/oauth/onboarding")
      view |> render_click("toggle_terms")

      assert {:error, {:live_redirect, %{to: "/project"}}} =
               view |> render_click("continue")
    end

    test "redirects member to / when terms accepted", %{conn: conn} do
      # Create a non-creator member instead
      user = Factories.insert!(:member, %{creator: false})
      {:ok, conn: conn, user: _user} = login(user, %{conn: conn})

      {:ok, view, _html} = live(conn, "/user/oauth/onboarding")
      view |> render_click("toggle_terms")

      assert {:error, {:live_redirect, %{to: "/"}}} =
               view |> render_click("continue")
    end
  end
end
