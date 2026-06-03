defmodule Systems.Account.TermsAndPrivacyViewTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Core.Repo
  alias Frameworks.Concept.LiveContext
  alias Systems.Account

  setup %{conn: conn} do
    isolate_signals()

    {:ok, user} =
      %Account.User{}
      |> Account.User.sso_changeset(%{
        email: "sso-#{System.unique_integer([:positive])}@example.com",
        displayname: "SSO User",
        creator: true,
        verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      })
      |> Repo.insert()

    conn = conn |> Map.put(:request_path, "/user/onboarding")
    session = %{"live_context" => LiveContext.new(%{user_id: user.id})}

    %{conn: conn, user: user, session: session}
  end

  describe "rendering" do
    test "renders title, body, checkbox, and continue button", %{conn: conn, session: session} do
      {:ok, view, html} =
        live_isolated(conn, Account.TermsAndPrivacyView, session: session)

      assert html =~ "Welcome"
      assert view |> has_element?("[data-testid='terms-and-privacy-view']")
      assert view |> has_element?("[data-testid='terms-and-privacy-onboarding-terms']")
      assert view |> has_element?("[data-testid='onboarding-continue']")
    end
  end

  describe "continue event" do
    test "does not activate the user when terms not accepted", %{
      conn: conn,
      session: session,
      user: user
    } do
      {:ok, view, _html} =
        live_isolated(conn, Account.TermsAndPrivacyView, session: session)

      _ = view |> render_click("continue")

      assert %Account.User{confirmed_at: nil} = Account.Public.get_user!(user.id)
    end

    test "activates the user when terms accepted", %{conn: conn, session: session, user: user} do
      {:ok, view, _html} =
        live_isolated(conn, Account.TermsAndPrivacyView, session: session)

      view |> render_click("toggle_terms")
      _ = view |> render_click("continue")

      assert %Account.User{confirmed_at: confirmed_at} = Account.Public.get_user!(user.id)
      assert confirmed_at != nil
    end
  end
end
