defmodule Systems.Pool.CriteriaFilters do
  @moduledoc """
  Defines filters used to filter students in the overview page of the pool.
  """
  use Core.Enums.Base,
      {:criteria_filters, [:iba, :bk]}

  def include?(codes, nil) when is_list(codes), do: true
  def include?(codes, []) when is_list(codes), do: true

  def include?(codes, filters) when is_list(codes) and is_list(filters) do
    filters = filters |> Enum.filter(&member?(&1))

    filter_count = Enum.count(filters)
    match_count = Enum.count(Enum.filter(filters, &include?(codes, &1)))
    # each filter should have at least one match (AND)
    filter_count == match_count
  end

  def include?(codes, filter) when is_list(codes) do
    Enum.count(Enum.filter(codes, &include?(&1, filter))) > 0
  end

  def include?(code, filter) when is_atom(filter), do: include?(code, Atom.to_string(filter))

  def include?(code, filter) when is_binary(filter),
    do: String.contains?(Atom.to_string(code), filter)

  def include?(_, _), do: false
end
