defmodule Systems.Account.OnboardingPageTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  # `:features` has moved to the Pool-scoped onboarding, so a confirmed
  # user's account onboarding is now just `:profile` (with an optional
  # `:activate_account` step for unconfirmed users, and a leading
  # `:terms_and_privacy` for passwordless users).

  setup %{conn: conn} do
    isolate_signals()

    user = Factories.insert!(:member)
    {:ok, conn: conn, user: _user} = login(user, %{conn: conn})

    %{conn: conn, user: user}
  end

  describe "rendering" do
    test "renders profile step first for a confirmed user", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/user/onboarding")

      assert view |> has_element?("[data-testid='profile-view']")
    end

    test "renders continue button", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/user/onboarding")

      assert html =~ "continue" or html =~ "Continue" or html =~ "Doorgaan"
    end
  end

  describe "skip event" do
    test "redirects to home when skip is clicked", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/user/onboarding")

      assert {:error, {:live_redirect, %{to: "/"}}} = view |> render_click("skip")
    end
  end

  describe "continue event" do
    test "redirects to home on last step (profile is the only step)", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/user/onboarding")

      assert {:error, {:live_redirect, %{to: "/"}}} = view |> render_click("continue")
    end
  end

  describe "unconfirmed user" do
    test "has profile and activate_account steps", %{conn: conn} do
      unconfirmed_user = Factories.insert!(:member, %{confirmed_at: nil})

      {:ok, conn: logged_in_conn, user: _user} = login(unconfirmed_user, %{conn: conn})

      {:ok, view, _html} = live(logged_in_conn, "/user/onboarding")

      # Step 1: profile
      assert view |> has_element?("[data-testid='profile-view']")

      # Step 2: activate_account
      html = view |> render_click("continue")
      assert html =~ "activate" or html =~ "Activate" or html =~ "activeer" or html =~ "Activeer"
    end

    test "redirects to home after activate_account step", %{conn: conn} do
      unconfirmed_user = Factories.insert!(:member, %{confirmed_at: nil})

      {:ok, conn: logged_in_conn, user: _user} = login(unconfirmed_user, %{conn: conn})

      {:ok, view, _html} = live(logged_in_conn, "/user/onboarding")

      # Navigate through: profile -> activate_account -> home
      view |> render_click("continue")
      assert {:error, {:live_redirect, %{to: "/"}}} = view |> render_click("continue")
    end
  end
end
