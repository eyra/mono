defmodule Systems.Payment.Provider.LocalControllerTest do
  @moduledoc """
  The local payment simulator stands in for the OPP checkout page in dev/E2E.
  It is the only way a pay-in can be completed or failed without a real
  provider, so its two POST endpoints must actually move the transaction and
  land the researcher back on the assignment they were paying for.

  The routes are compiled in only when `:enable_e2e_support` is set, which is
  the case for :test (see config/test.exs).
  """
  use CoreWeb.ConnCase, async: false

  alias Core.Repo
  alias Systems.Bookkeeping
  alias Systems.Budget
  alias Systems.Fund

  describe "GET /payment/local/:uid" do
    test "renders the simulator with a complete and a fail action", %{conn: conn} do
      %{transaction: transaction} = setup_transaction()

      html = conn |> get(~p"/payment/local/#{transaction.transaction_id}") |> html_response(200)

      assert html =~ transaction.transaction_id
      assert html =~ "local-payment-complete-button"
      assert html =~ "local-payment-fail-button"
      assert html =~ "/payment/local/#{transaction.transaction_id}/complete"
      assert html =~ "/payment/local/#{transaction.transaction_id}/fail"
    end
  end

  describe "POST /payment/local/:uid/complete" do
    test "completes the transaction and returns to the assignment", %{conn: conn} do
      %{transaction: transaction, assignment: assignment} = setup_transaction()

      conn = simulate(conn, transaction, "complete")

      assert redirected_to(conn) == "/assignment/#{assignment.id}/content"
      assert %{status: :completed} = Repo.get!(Budget.TransactionModel, transaction.id)
    end

    test "still returns to the assignment when the transaction is already completed", %{
      conn: conn
    } do
      %{transaction: transaction, assignment: assignment} = setup_transaction(status: :completed)

      conn = simulate(conn, transaction, "complete")

      assert redirected_to(conn) == "/assignment/#{assignment.id}/content"
      assert %{status: :completed} = Repo.get!(Budget.TransactionModel, transaction.id)
    end

    test "falls back to the home page when the fund has no assignment", %{conn: conn} do
      %{transaction: transaction} = setup_transaction(assignment: false)

      conn = simulate(conn, transaction, "complete")

      assert redirected_to(conn) == "/"
    end

    test "404s on an unknown provider uid", %{conn: conn} do
      %{transaction: transaction} = setup_transaction()
      conn = get(conn, ~p"/payment/local/#{transaction.transaction_id}")

      assert_error_sent(404, fn ->
        post(recycle(conn), "/payment/local/does-not-exist/complete", %{
          "_csrf_token" => csrf_token(conn)
        })
      end)
    end
  end

  describe "POST /payment/local/:uid/fail" do
    test "fails the transaction and returns to the assignment", %{conn: conn} do
      %{transaction: transaction, assignment: assignment} = setup_transaction()

      conn = simulate(conn, transaction, "fail")

      assert redirected_to(conn) == "/assignment/#{assignment.id}/content"
      assert %{status: :failed} = Repo.get!(Budget.TransactionModel, transaction.id)
    end

    test "leaves an already-completed transaction credited", %{conn: conn} do
      %{transaction: transaction, assignment: assignment} = setup_transaction(status: :completed)

      conn = simulate(conn, transaction, "fail")

      assert redirected_to(conn) == "/assignment/#{assignment.id}/content"
      assert %{status: :completed} = Repo.get!(Budget.TransactionModel, transaction.id)
    end
  end

  # The simulator posts from its own rendered form, so drive it the same way:
  # GET the page to establish the session, then post back its CSRF token.
  defp simulate(conn, %{transaction_id: uid}, action) do
    conn = get(conn, ~p"/payment/local/#{uid}")

    recycle(conn)
    |> post("/payment/local/#{uid}/#{action}", %{"_csrf_token" => csrf_token(conn)})
  end

  defp csrf_token(conn) do
    [_, token] = Regex.run(~r/name="_csrf_token" value="([^"]+)"/, conn.resp_body)
    token
  end

  defp setup_transaction(opts \\ []) do
    status = Keyword.get(opts, :status, :pending)
    with_assignment? = Keyword.get(opts, :assignment, true)

    currency_ledger = ensure_currency_ledger(:EUR)
    user = Factories.insert!(:member)

    fund =
      %Fund.Model{}
      |> Ecto.Changeset.change(%{name: "local-ctrl-#{System.unique_integer([:positive])}"})
      |> Ecto.Changeset.put_assoc(:auth_node, Factories.build(:auth_node))
      |> Ecto.Changeset.put_assoc(
        :available,
        Bookkeeping.AccountModel.create({:fund, Ecto.UUID.generate()})
      )
      |> Ecto.Changeset.put_assoc(
        :pending,
        Bookkeeping.AccountModel.create({:reserve, Ecto.UUID.generate()})
      )
      |> Ecto.Changeset.put_change(:currency_ledger_id, currency_ledger.id)
      |> Repo.insert!()

    assignment = if with_assignment?, do: insert_assignment(fund)

    {:ok, transaction} =
      %Budget.TransactionModel{}
      |> Budget.TransactionModel.changeset(%{
        transaction_id: "provider-" <> Ecto.UUID.generate(),
        status: status,
        idempotence_key: Ecto.UUID.generate(),
        invoice_id: "NEXT-LOCAL-#{System.unique_integer([:positive])}",
        subject_count: 10
      })
      |> Ecto.Changeset.put_change(:user_id, user.id)
      |> Ecto.Changeset.put_change(:target_fund_id, fund.id)
      |> Repo.insert()

    %{transaction: transaction, fund: fund, user: user, assignment: assignment}
  end

  defp insert_assignment(fund) do
    info = Factories.insert!(:assignment_info, %{subject_count: 10, subject_reward: 500})

    Factories.insert!(:assignment, %{
      info: info,
      fund: fund,
      status: :online,
      special: :questionnaire
    })
  end

  defp ensure_currency_ledger(currency) do
    case Budget.CurrencyLedgerModel.get_by_currency(currency) do
      nil -> Budget.CurrencyLedgerModel.create(currency) |> Repo.insert!()
      existing -> existing |> Repo.preload([:inbound, :outbound])
    end
  end
end
