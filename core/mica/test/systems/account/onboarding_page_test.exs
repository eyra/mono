defmodule Systems.Account.OnboardingPageTest do
  use MicaWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Systems.Account

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

  describe "return_to" do
    test "continues to a same-site return_to", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/user/onboarding?return_to=%2Fpool%2Fpanl%2Fjoin")

      assert {:error, {:live_redirect, %{to: "/pool/panl/join"}}} = render_click(view, "skip")
    end

    test "return_to accepts only same-site paths", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/user/onboarding?return_to=%2F%2Fexample.org%2Fx")

      assert {:error, {:live_redirect, %{to: "/"}}} = render_click(view, "skip")
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

  describe "terms step for a passwordless user" do
    test "clears the terms error once the terms are accepted", %{conn: conn} do
      {:ok, user} =
        %Account.User{}
        |> Account.User.sso_changeset(%{
          email: "sso-#{System.unique_integer([:positive])}@example.com",
          displayname: "SSO User",
          creator: true,
          verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })
        |> Mica.Repo.insert()

      {:ok, conn: logged_in_conn, user: _user} = login(user, %{conn: conn})
      {:ok, view, _html} = live(logged_in_conn, "/user/onboarding")

      [terms_view] = live_children(view)
      error = "Please accept the terms and privacy statement to continue."

      render_click(terms_view, "continue")
      assert render(view) =~ error

      render_click(terms_view, "toggle_terms")
      render_click(terms_view, "continue")

      assert view |> has_element?("[data-testid='profile-view']")
      refute render(view) =~ error
    end
  end
end
