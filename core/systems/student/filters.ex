defmodule Systems.Student.Filters do
  @moduledoc """
  Defines filters used to filter students in the overview page of the pool.
  """
  use Core.Enums.Base,
      {:student_filters, [:inactive, :active, :passed]}

  alias Systems.{
    Budget,
    Bookkeeping,
    Pool
  }

  def include?(_student, nil), do: true
  def include?(_student, []), do: true

  def include?(student, filters, %Pool.Model{} = pool) when is_list(filters) do
    filters = filters |> Enum.filter(&Enum.member?(values(), &1))



    filter_count = Enum.count(filters)
    match_count = Enum.count(filters, &include?(student, &1, pool))
    # each filter should match (AND)
    filter_count == match_count
  end

  def include?(student, filter, %Pool.Model{} = pool), do: state(student, pool) == filter

  defp state(%Core.Accounts.User{} = student, pool) do
    Budget.Public.list_wallets(student)
    |> Enum.filter(&Pool.Public.is_wallet_related?(pool, &1))
    |> state(pool)
  end

  defp state([] = _wallets, _pool), do: :inactive

  defp state(%Bookkeeping.AccountModel{} = wallet, pool) do
    if Pool.Public.is_target_achieved?(pool, wallet) do
      :passed
    else
      :active
    end
  end

  defp state([wallet] = _wallets, pool), do: state(wallet, pool)

  defp state([wallet | tail] = _wallets, pool) do
    if state(wallet, pool) == :passed do
      :passed
    else
      state(tail, pool)
    end
  end
end
