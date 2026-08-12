defmodule Systems.Fund.BalanceRaceTest do
  @moduledoc """
  Proves the `SELECT ... FOR UPDATE` guard in `Fund.Public.create_reward/4`
  serializes concurrent reservations against the same fund.

  Runs outside the SQL sandbox (`:auto` mode, truncating afterwards): two
  reservations have to contend for the same row on *separate* database
  connections, which a single shared sandbox connection cannot express.
  """
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Core.Repo
  alias Ecto.Adapters.SQL.Sandbox
  alias Systems.Bookkeeping
  alias Systems.Fund

  setup do
    Sandbox.mode(Repo, :auto)
    on_exit(&reset_sandbox/0)

    currency = Fund.Factories.create_currency("race_currency", :legal, "ƒ", 2)
    fund = Fund.Factories.create_fund("race", currency)
    participants = Enum.map(1..2, &insert_participant/1)

    {:ok, fund: fund, participants: participants, balance: available_balance(fund)}
  end

  test "concurrent reservations cannot overdraw the fund", %{
    fund: fund,
    participants: participants,
    balance: balance
  } do
    amount = div(balance, 2) + 1

    # credo:disable-for-next-line Credo.Check.Warning.NoRepoTransaction
    {:ok, tasks} = Repo.transaction(fn -> reserve_while_locked(fund, amount, participants) end)
    results = Task.await_many(tasks)

    assert Enum.count(results, &reserved?/1) == 1
    assert Enum.count(results, &no_funding?/1) == 1
    assert available_balance(fund) == balance - amount
  end

  defp reserve_while_locked(
         %Fund.Model{available: %{id: account_id}} = fund,
         amount,
         participants
       ) do
    lock_account(account_id)
    tasks = Enum.map(participants, &reserve_task(fund, amount, &1))
    # Both tasks park on the locked row; they are released together at commit.
    Process.sleep(200)
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

  defp reserved?({:ok, _}), do: true
  defp reserved?(_), do: false

  defp no_funding?({:error, :fund_balance, :no_funding, _}), do: true
  defp no_funding?(_), do: false

  defp available_balance(%Fund.Model{available: %{id: account_id}}) do
    Bookkeeping.AccountModel.balance(Repo.get!(Bookkeeping.AccountModel, account_id))
  end

  defp insert_participant(_), do: Core.Factories.insert!(:member, %{creator: false})

  defp reset_sandbox do
    truncate_all()
    Sandbox.mode(Repo, :manual)
  end

  defp truncate_all do
    %{rows: rows} = Repo.query!("SELECT tablename FROM pg_tables WHERE schemaname = 'public'")

    tables =
      rows
      |> List.flatten()
      |> List.delete("schema_migrations")
      |> Enum.join(", ")

    Repo.query!("TRUNCATE #{tables} RESTART IDENTITY CASCADE")
  end
end
