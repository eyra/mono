defmodule Systems.Fund.BalanceRaceTest do
  @moduledoc """
  Proves the `SELECT ... FOR UPDATE` guard in `Fund.Public.create_reward/4`
  serializes concurrent reservations against the same fund.

  Runs outside the SQL sandbox (`:auto` mode, truncating its fixture tables
  afterwards): two reservations have to contend for the same row on *separate*
  database connections, which a single shared sandbox connection cannot express.
  """
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Core.Repo
  alias Ecto.Adapters.SQL.Sandbox
  alias Systems.Bookkeeping
  alias Systems.Fund

  @contention_timeout 10_000
  @reservation_timeout 30_000

  setup do
    Sandbox.mode(Repo, :auto)
    on_exit(&reset_sandbox/0)

    suffix = System.unique_integer([:positive])
    currency = Fund.Factories.create_currency("race_currency_#{suffix}", :legal, "ƒ", 2)
    fund = Fund.Factories.create_fund("race_#{suffix}", currency)
    participants = Enum.map(1..2, &insert_participant/1)

    {:ok, fund: fund, participants: participants, balance: available_balance(fund)}
  end

  test "concurrent reservations cannot overdraw the fund", %{
    fund: fund,
    participants: participants,
    balance: balance
  } do
    amount = div(balance, 2) + 1
    assert amount <= balance, "fixture balance #{balance} is too low for one reservation to fit"

    # credo:disable-for-next-line Credo.Check.Warning.NoRepoTransaction
    {:ok, tasks} = Repo.transaction(fn -> reserve_while_locked(fund, amount, participants) end)
    results = Task.await_many(tasks, @reservation_timeout)

    assert Enum.count(results, &reserved?/1) == 1
    assert Enum.count(results, &no_funding?/1) == 1
    assert available_balance(fund) == balance - amount
  end

  defp reserve_while_locked(%Fund.Model{available: %{id: account_id}} = fund, amount, participants) do
    lock_account(account_id)
    tasks = Enum.map(participants, &reserve_task(fund, amount, &1))
    await_lock_waiters(length(tasks))
    tasks
  end

  defp lock_account(account_id) do
    Repo.one!(from(a in Bookkeeping.AccountModel, where: a.id == ^account_id, lock: "FOR UPDATE"))
  end

  defp reserve_task(fund, amount, %{id: user_id} = participant) do
    Task.async(fn ->
      Fund.Public.create_reward(fund, amount, participant, "race,user=#{user_id}")
    end)
  end

  defp await_lock_waiters(count) do
    await_lock_waiters(count, System.monotonic_time(:millisecond) + @contention_timeout)
  end

  defp await_lock_waiters(count, deadline) do
    cond do
      lock_waiter_count() >= count -> :ok
      System.monotonic_time(:millisecond) > deadline -> flunk(no_contention_message(count))
      true -> retry_lock_waiters(count, deadline)
    end
  end

  defp retry_lock_waiters(count, deadline) do
    Process.sleep(25)
    await_lock_waiters(count, deadline)
  end

  defp lock_waiter_count do
    %{rows: [[count]]} =
      Repo.query!("""
      SELECT count(*) FROM pg_stat_activity
      WHERE datname = current_database()
        AND wait_event_type = 'Lock'
        AND pid <> pg_backend_pid()
      """)

    count
  end

  defp no_contention_message(count) do
    "expected #{count} reservations to block on the locked fund account, saw #{lock_waiter_count()}"
  end

  defp reserved?({:ok, _}), do: true
  defp reserved?(_), do: false

  defp no_funding?({:error, :fund_balance, :no_funding, _}), do: true
  defp no_funding?(_), do: false

  defp available_balance(%Fund.Model{available: %{id: account_id}}) do
    Bookkeeping.AccountModel.balance(Repo.get!(Bookkeeping.AccountModel, account_id))
  end

  defp insert_participant(_), do: Core.Factories.insert!(:member, %{creator: false})

  defp reset_sandbox do
    truncate_fixtures()
  after
    Sandbox.mode(Repo, :manual)
  end

  defp truncate_fixtures do
    Repo.query!("""
    TRUNCATE users, funds, book_accounts, currencies, text_bundles, authorization_nodes CASCADE
    """)
  end
end
