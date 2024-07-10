defmodule Frameworks.Utility.ConfigHelpers do
  def from_json_string(string) do
    Jason.decode!(string)
  end

  def get!(type, keywords, key, valid_values \\ []) do
    case get(type, keywords, key, valid_values) do
      {:ok, value} -> value
      {:error, error} -> raise error
    end
  end

  def get(_, _, _, valid_values \\ [])

  def get(type, keywords, key, valid_values) when is_list(keywords) and is_atom(key) do
    if Keyword.keyword?(keywords) do
      if Keyword.has_key?(keywords, key) do
        value(type, Keyword.get(keywords, key), valid_values)
      else
        {:error, "Keyword does not have value for key #{key}"}
      end
    else
      {:error, "List is not a Keyword"}
    end
  end

  def get(type, %{} = map, key, valid_values) do
    cond do
      Map.has_key?(map, key) ->
        value(type, Map.get(map, key), valid_values)

      Map.has_key?(map, Atom.to_string(key)) ->
        value(type, Map.get(map, Atom.to_string(key)), valid_values)

      true ->
        {:error, "Map does not have value for key #{key}"}
    end
  end

  def value(:atom, string, valid_atoms) when is_binary(string) do
    value(:atom, String.to_existing_atom(string), valid_atoms)
  end

  def value(:atom, atom, valid_atoms) when is_atom(atom) do
    if Enum.member?(valid_atoms, atom) do
      {:ok, atom}
    else
      {:error, "Atom '#{atom}' is invalid, expecting one of #{inspect(valid_atoms)}"}
    end
  end

  def value(:integer, string, valid_values) when is_binary(string) do
    case Integer.parse(string) do
      {integer, _} ->
        value(:integer, integer, valid_values)

      :error ->
        {:error, "Value '#{string}' is invalid, expecting an integer"}
    end
  end

  def value(:integer, integer, _) when is_integer(integer) do
    {:ok, integer}
  end

  def value(:integer, value, _) do
    {:error, "Value '#{value}' is invalid, expecting an integer"}
  end

  def value(:string, atom, valid_values) when is_atom(atom) do
    value(:string, Atom.to_string(atom), valid_values)
  end

  def value(:string, string, _) when is_binary(string) do
    {:ok, string}
  end

  def value(type, value, []) do
    {:error, "Value '#{value}' is invalid, expecting a #{type}"}
  end

  def value(_type, value, valid_values) do
    {:error, "Value '#{value}' is invalid, expecting one of #{inspect(valid_values)}"}
  end
end
