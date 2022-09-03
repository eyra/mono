defmodule Frameworks.Utility.Identifier do
  def to_string(%{identifier: identifier}), do: __MODULE__.to_string(identifier)

  def to_string([_ | _] = identifier) do
    identifier
    |> Enum.map_join("_", &stringafy(&1))
  end

  defp stringafy(":" <> sub_string), do: sub_string
  defp stringafy(term) when is_binary(term), do: term

  def from_string(code, include_year?) when is_atom(code),
    do: from_string(Atom.to_string(code), include_year?)

  def from_string(string, include_year?) do
    string
    |> String.split("_")
    |> Enum.map(&atomify(&1, include_year?))
  end

  defp atomify("year" <> year, true), do: ":year#{year}"
  defp atomify("20" <> year, true), do: ":20#{year}"
  defp atomify(term, _), do: term
end
