defmodule Systems.Account.PayoutsViewTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Core.Repo
  alias Frameworks.Concept.LiveContext
  alias Systems.Account
  alias Systems.Fund

  setup do
    isolate_signals()
    # No merchant_uid -> verification_status is :not_verified without any OPP call.
    user = Factories.insert!(:member, %{creator: false})
    %{user: user}
  end

  defp mount(conn, user) do
    conn = conn |> Map.put(:request_path, "/user/profile/payouts")
    session = %{"live_context" => LiveContext.new(%{user_id: user.id})}
    live_isolated(conn, Account.PayoutsView, session: session)
  end

  defp payout(user, cents, status, inserted_at) do
    Repo.insert!(%Fund.PayoutModel{
      user_id: user.id,
      amount_cents: cents,
      currency: "eur",
      status: status,
      inserted_at: inserted_at,
      updated_at: inserted_at
    })
  end

  describe "bank section" do
    test "renders the not-verified status with an Add button", %{conn: conn, user: user} do
      {:ok, view, html} = mount(conn, user)

      assert view |> has_element?("[data-testid='payouts-view']")
      assert html =~ "Not verified"
      assert html =~ "Add"
    end
  end

  describe "overview" do
    test "shows the empty-state message when there are no payouts", %{conn: conn, user: user} do
      {:ok, _view, html} = mount(conn, user)

      assert html =~ "No payouts have been made yet"
    end

    test "renders the history table and year filter when payouts exist", %{
      conn: conn,
      user: user
    } do
      payout(user, 500, :completed, ~N[2025-09-25 10:00:00])

      {:ok, view, html} = mount(conn, user)

      assert view |> has_element?("[data-testid='payouts-table']")
      assert view |> has_element?("[data-testid='year-filter']")
      assert html =~ "2025"
      # status renders as a chip (same component as the pay-in status)
      assert view |> has_element?("[data-testid='payouts-table'] .prism-tag")
      assert html =~ "Paid out"
    end

    test "switching the year filter re-renders the selected year", %{conn: conn, user: user} do
      payout(user, 500, :completed, ~N[2025-09-25 10:00:00])
      payout(user, 1000, :completed, ~N[2024-03-01 10:00:00])

      {:ok, view, _html} = mount(conn, user)

      html = view |> render_click("select_year", %{"year" => "2024"})
      assert html =~ "2024"
    end
  end
end
