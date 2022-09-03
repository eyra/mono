defmodule Systems.Pool.StudentFilters do
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

  def include?(student, filters) when is_list(filters) do
    filters = filters |> Enum.filter(&Enum.member?(values(), &1))

    filter_count = Enum.count(filters)
    match_count = Enum.count(Enum.filter(filters, &include?(student, &1)))
    # each filter should have at least one match (AND)
    filter_count == match_count
  end

  def include?(student, filter), do: state(student) == filter

  defp state(%Core.Accounts.User{} = student) do
    Budget.Context.list_wallets(student)
    |> state()
  end

  defp state([] = _wallets), do: :inactive

  defp state(%Bookkeeping.AccountModel{} = wallet) do
    if Pool.Context.is_target_achieved?(wallet) do
      :passed
    else
      :active
    end
  end

  defp state([wallet] = _wallets), do: state(wallet)

  defp state([wallet, tail] = _wallets) do
    if state(wallet) == :passed do
      :passed
    else
      state(tail)
    end
  end
end
