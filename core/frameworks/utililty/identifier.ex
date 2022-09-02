defmodule Frameworks.Utility.Identifier do
  # Backwards compatible from identifier to old study program code format (intentionally ugly code)
  def to_string(["vu", "sbe", "bk", ":year1", ":2021"]), do: :bk_1
  def to_string(["vu", "sbe", "bk", ":year1", ":resit", ":2021"]), do: :bk_1_h
  def to_string(["vu", "sbe", "bk", ":year2", ":2021"]), do: :bk_2
  def to_string(["vu", "sbe", "bk", ":year2", ":resit", ":2021"]), do: :bk_2_h
  def to_string(["vu", "sbe", "iba", ":year1", ":2021"]), do: :iba_1
  def to_string(["vu", "sbe", "iba", ":year1", ":resit", ":2021"]), do: :iba_1_h
  def to_string(["vu", "sbe", "iba", ":year2", ":2021"]), do: :iba_2
  def to_string(["vu", "sbe", "iba", ":year2", ":resit", ":2021"]), do: :iba_2_h

  def to_string(%{identifier: identifier}), do: __MODULE__.to_string(identifier)

  def to_string([_ | _] = identifier) do
    identifier
    |> Enum.map_join("_", &stringafy(&1))
  end

  defp stringafy(":" <> sub_string), do: sub_string
  defp stringafy(term) when is_binary(term), do: term

  # Backwards compatible from old study program code format to identifier (intentionally ugly code)
  def from_string(:bk_1, _), do: ["vu", "sbe", "bk", ":year1", ":2021"]
  def from_string(:bk_1_h, _), do: ["vu", "sbe", "bk", ":year1", ":resit", ":2021"]
  def from_string(:bk_2, _), do: ["vu", "sbe", "bk", ":year2", ":2021"]
  def from_string(:bk_2_h, _), do: ["vu", "sbe", "bk", ":year2", ":resit", ":2021"]
  def from_string(:iba_1, _), do: ["vu", "sbe", "iba", ":year1", ":2021"]
  def from_string(:iba_1_h, _), do: ["vu", "sbe", "iba", ":year1", ":resit", ":2021"]
  def from_string(:iba_2, _), do: ["vu", "sbe", "iba", ":year2", ":2021"]
  def from_string(:iba_2_h, _), do: ["vu", "sbe", "iba", ":year2", ":resit", ":2021"]

  def from_string(string, include_year?) do
    string
    |> String.split("_")
    |> Enum.map(&atomify(&1, include_year?))
  end

  defp atomify("year" <> year, true), do: ":year#{year}"
  defp atomify("20" <> year, true), do: ":20#{year}"
  defp atomify(term, _), do: term
end
