defmodule Systems.Student.Codes do
  @moduledoc """
    Defines study program codes used as user feature for vu students.
  """

  alias Systems.{
    Org,
    Content
  }

  def values(),
    do: [
      :vu_sbe_bk_1,
      :vu_sbe_bk_1_h,
      :vu_sbe_bk_2,
      :vu_sbe_bk_2_h,
      :vu_sbe_iba_1,
      :vu_sbe_iba_1_h,
      :vu_sbe_iba_2,
      :vu_sbe_iba_2_h
    ]

  def year_to_string(:first), do: "1"
  def year_to_string(:second), do: "2"

  def parse_year("first"), do: "1"
  def parse_year("second"), do: "2"
  def parse_year("year1"), do: "1"
  def parse_year("year2"), do: "2"
  def parse_year("1st"), do: "1"
  def parse_year("2nd"), do: "2"
  def parse_year(year) when is_binary(year), do: year

  def year?(value, year) when is_atom(value) and is_atom(year) do
    year?(value, year_to_string(year))
  end

  def year?(value, year) when is_atom(value) and is_binary(year) do
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

  def first_year_active?(nil), do: false

  def first_year_active?(active_values) do
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
    |> Enum.find(&year?(&1, year)) != nil
  end

  def values_by_year(year) do
    values()
    |> Enum.filter(&year?(&1, year))
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

  defp convert_to_label(value, active_values) when is_atom(value) do
    value_as_string =
      value
      |> Atom.to_string()
      |> translate()

    active =
      active_values
      |> Enum.member?(value)

    %{id: value, value: value_as_string, active: active}
  end

  def translate(value) do
    Gettext.dgettext(CoreWeb.Gettext, "eyra-enums", "study_pogram_codes.#{value}")
  end

  def text(code) when is_atom(code) do
    locale = Gettext.get_locale(CoreWeb.Gettext)

    code
    |> Atom.to_string()
    |> Frameworks.Utility.Identifier.from_string(true)
    |> Org.Public.get_node!(short_name_bundle: Content.TextBundleModel.preload_graph(:full))
    |> Map.get(:short_name_bundle)
    |> Content.TextBundleModel.text(locale)
  end
end
