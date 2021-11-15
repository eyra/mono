defmodule Core.Enums.StudyProgramCodes do
  @moduledoc """
    Defines study program codes used as user feature for vu students.
  """
  use Core.Enums.Base,
      {:study_pogram_codes, [:bk_1, :bk_1_h, :bk_2, :bk_2_h, :iba_1, :iba_1_h, :iba_2, :iba_2_h]}

  def year_to_string(:first), do: "1"
  def year_to_string(:second), do: "2"

  def is_year?(value, year) when is_atom(value) do
    Atom.to_string(value) |> String.contains?(year_to_string(year))
  end

  def is_first_year_active?(nil), do: false

  def is_first_year_active?(active_values) do
    active_values
    # first year is active when no 2nd year value is selected
    |> Enum.find(&is_year?(&1, :second)) == nil
  end

  def values_by_year(year) do
    values()
    |> Enum.filter(&is_year?(&1, year))
  end

  def labels_by_year(year, nil) do
    labels_by_year(year, [])
  end

  def labels_by_year(year, active_values) when is_list(active_values) do
    values_by_year(year)
    |> Enum.map(&convert_to_label(&1, active_values))
  end

  def labels_by_year(year, active_value) do
    labels_by_year(year, [active_value])
  end
end
