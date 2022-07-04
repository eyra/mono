defmodule Core.Pools.CriteriaFilters do
  @moduledoc """
  Defines filters used to filter students in the overview page of the pool.
  """
  use Core.Enums.Base,
      {:criteria_filters, [:iba, :bk, :year1, :year2, :resit]}

  def include?(codes, nil) when is_list(codes), do: true
  def include?(codes, []) when is_list(codes), do: true

  def include?(codes, filters) when is_list(codes) and is_list(filters) do
    filters = filters |> Enum.filter(&Enum.member?(values(), &1))

    filter_count = Enum.count(filters)
    match_count = Enum.count(Enum.filter(filters, &include?(codes, &1)))
    # each filter should have at least one match (AND)
    filter_count == match_count
  end

  def include?(codes, filter) when is_list(codes) do
    Enum.count(Enum.filter(codes, &include?(&1, filter))) > 0
  end

  def include?(code, :year1), do: String.contains?(Atom.to_string(code), "_1")
  def include?(code, :year2), do: String.contains?(Atom.to_string(code), "_2")
  def include?(code, :iba), do: String.contains?(Atom.to_string(code), "iba")
  def include?(code, :bk), do: String.contains?(Atom.to_string(code), "bk")
  def include?(code, :resit), do: String.contains?(Atom.to_string(code), "_h")
  def include?(_, _), do: false
end
