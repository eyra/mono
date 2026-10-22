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

  def get_attribute!(identifier, attribute) do
    if value = get_attribute(identifier, attribute) do
      value
    else
      raise ArgumentError, "Attribute #{inspect(attribute)} not found in #{inspect(identifier)}"
    end
  end

  def get_attribute(%{identifier: identifier}, attribute) do
    get_attribute(identifier, attribute)
  end

  def get_attribute(identifier, attribute) when is_atom(attribute) do
    get_attribute(identifier, Atom.to_string(attribute))
  end

  def get_attribute([], _attribute), do: nil

  def get_attribute([h | t], attribute) when is_binary(h) and is_binary(attribute) do
    case String.split(h, "=") do
      [^attribute, value] -> value
      _ -> get_attribute(t, attribute)
    end
  end

  defp atomify("year" <> year, true), do: ":year#{year}"
  defp atomify("20" <> year, true), do: ":20#{year}"
  defp atomify("resit", true), do: ":resit"
  defp atomify(term, _), do: term
end
