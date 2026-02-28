defmodule Systems.Account.OnboardingPageTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Systems.Pool

  setup %{conn: conn} do
    isolate_signals()

    user = Factories.insert!(:member)

    panl_pool =
      Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

    Pool.Public.add_participant!(panl_pool, user)

    {:ok, conn: conn, user: _user} = login(user, %{conn: conn})

    %{conn: conn, user: user}
  end

  describe "rendering" do
    test "renders profile step first for PANL participant", %{conn: conn} do
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
    test "advances to features step on first continue", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/user/onboarding")

      # First step is profile, continue should advance to features
      html = view |> render_click("continue")
      assert html =~ "features" or has_element?(view, "[data-testid='features-view']")
    end

    test "redirects to home on last step", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/user/onboarding")

      # First continue: profile -> features
      view |> render_click("continue")
      # Second continue: features -> home (last step)
      assert {:error, {:live_redirect, %{to: "/"}}} = view |> render_click("continue")
    end
  end

  describe "non-PANL user" do
    test "renders profile step for non-PANL user", %{conn: conn} do
      non_panl_user = Factories.insert!(:member)
      {:ok, conn: logged_in_conn, user: _user} = login(non_panl_user, %{conn: conn})

      {:ok, view, _html} = live(logged_in_conn, "/user/onboarding")

      assert view |> has_element?("[data-testid='profile-view']")
    end

    test "redirects non-PANL user to home on continue", %{conn: conn} do
      non_panl_user = Factories.insert!(:member)
      {:ok, conn: logged_in_conn, user: _user} = login(non_panl_user, %{conn: conn})

      {:ok, view, _html} = live(logged_in_conn, "/user/onboarding")

      # Non-PANL confirmed user has only :profile step, so continue should redirect
      assert {:error, {:live_redirect, %{to: "/"}}} = view |> render_click("continue")
    end
  end

  describe "unconfirmed PANL participant" do
    test "includes confirm_email as third step", %{conn: conn} do
      unconfirmed_user = Factories.insert!(:member, %{confirmed_at: nil})

      panl_pool =
        Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      Pool.Public.add_participant!(panl_pool, unconfirmed_user)

      {:ok, conn: logged_in_conn, user: _user} = login(unconfirmed_user, %{conn: conn})

      {:ok, view, _html} = live(logged_in_conn, "/user/onboarding")

      # Step 1: profile
      assert view |> has_element?("[data-testid='profile-view']")

      # Step 2: features
      view |> render_click("continue")
      assert view |> has_element?("[data-testid='features-view']")

      # Step 3: confirm_email (no specific view, just title/body)
      html = view |> render_click("continue")
      # Should show confirm email content
      assert html =~ "confirm" or html =~ "Confirm" or html =~ "bevestig" or html =~ "Bevestig"
    end

    test "redirects to home after confirm_email step", %{conn: conn} do
      unconfirmed_user = Factories.insert!(:member, %{confirmed_at: nil})

      panl_pool =
        Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      Pool.Public.add_participant!(panl_pool, unconfirmed_user)

      {:ok, conn: logged_in_conn, user: _user} = login(unconfirmed_user, %{conn: conn})

      {:ok, view, _html} = live(logged_in_conn, "/user/onboarding")

      # Navigate through all steps: profile -> features -> confirm_email -> home
      view |> render_click("continue")
      view |> render_click("continue")
      assert {:error, {:live_redirect, %{to: "/"}}} = view |> render_click("continue")
    end
  end

  describe "unconfirmed non-PANL user" do
    test "has profile and confirm_email steps", %{conn: conn} do
      unconfirmed_user = Factories.insert!(:member, %{confirmed_at: nil})

      {:ok, conn: logged_in_conn, user: _user} = login(unconfirmed_user, %{conn: conn})

      {:ok, view, _html} = live(logged_in_conn, "/user/onboarding")

      # Step 1: profile
      assert view |> has_element?("[data-testid='profile-view']")

      # Step 2: confirm_email
      html = view |> render_click("continue")
      assert html =~ "confirm" or html =~ "Confirm" or html =~ "bevestig" or html =~ "Bevestig"
    end

    test "redirects to home after confirm_email step", %{conn: conn} do
      unconfirmed_user = Factories.insert!(:member, %{confirmed_at: nil})

      {:ok, conn: logged_in_conn, user: _user} = login(unconfirmed_user, %{conn: conn})

      {:ok, view, _html} = live(logged_in_conn, "/user/onboarding")

      # Navigate through: profile -> confirm_email -> home
      view |> render_click("continue")
      assert {:error, {:live_redirect, %{to: "/"}}} = view |> render_click("continue")
    end
  end
end
