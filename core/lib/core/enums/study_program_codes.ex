defmodule Core.Enums.StudyProgramCodes do
  @moduledoc """
    Defines study program codes used as user feature for vu students.
  """
  use Core.Enums.Base,
      {:study_pogram_codes, [:bk_1, :bk_1_h, :bk_2, :bk_2_h, :iba_1, :iba_1_h, :iba_2, :iba_2_h]}

  def year_to_string(:first), do: "1"
  def year_to_string(:second), do: "2"

  def parse_year("first"), do: "1"
  def parse_year("second"), do: "2"
  def parse_year("year1"), do: "1"
  def parse_year("year2"), do: "2"
  def parse_year("1st"), do: "1"
  def parse_year("2nd"), do: "2"
  def parse_year(year) when is_binary(year), do: year

  def is_year?(value, year) when is_atom(value) and is_atom(year) do
    is_year?(value, year_to_string(year))
  end

  def is_year?(value, year) when is_atom(value) and is_binary(year) do
    Atom.to_string(value) |> String.contains?(parse_year(year))
  end

  def parse_study_program("resit"), do: "_h"
  def parse_study_program("re-sit"), do: "_h"
  def parse_study_program(study_program) when is_binary(study_program), do: study_program

  def is_study_program?(value, study_program) when is_atom(value) do
    study_program =
      study_program
      |> String.downcase()
      |> parse_study_program()

    Atom.to_string(value)
    |> String.contains?(study_program)
  end

  def is_first_year_active?(nil), do: false

  def is_first_year_active?(active_values) do
    # first year is active when no 2nd year value is selected
    not contains_year?(active_values, :second)
  end

  def contains_study_program?(nil, _), do: false

  def contains_study_program?(values, study_program) do
    values
    |> Enum.find(&is_study_program?(&1, study_program)) != nil
  end

  def contains_year?(nil, _), do: false

  def contains_year?(values, year) do
    values
    |> Enum.find(&is_year?(&1, year)) != nil
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
