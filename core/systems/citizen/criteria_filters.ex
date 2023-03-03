defmodule Systems.Citizen.CriteriaFilters do
  @moduledoc """
  Defines filters used to filter citizens in the overview page of the pool.
  """
  use Core.Enums.Base,
      {:criteria_filters, [:man, :woman, :x]}

  def include?(items, nil) when is_list(items), do: true
  def include?(items, []) when is_list(items), do: true

  def include?(items, filters) when is_list(items) and is_list(filters) do
    filters = filters |> Enum.filter(&Enum.member?(values(), &1))
    match_count = Enum.count(Enum.filter(filters, &include?(items, &1)))
    # have at least one match (OR)
    match_count > 0
  end

  def include?(items, filter) when is_list(items) do
    Enum.count(Enum.filter(items, &include?(&1, filter))) > 0
  end

  def include?(item, filter) when is_atom(item), do: item == filter
  def include?(item, filter) when is_binary(item), do: item == Atom.to_string(filter)
end
