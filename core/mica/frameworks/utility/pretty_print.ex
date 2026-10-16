defmodule Frameworks.Utility.PrettyPrint do
  def pretty_print({left, right}) do
    "{#{pretty_print(left)}, #{pretty_print(right)}}"
  end

  def pretty_print(list) when is_list(list) do
    "[#{Enum.map_join(list, ",", &pretty_print/1)}]"
  end

  def pretty_print(value) when is_atom(value) do
    ":#{value}"
  end

  def pretty_print(value) do
    "#{value}"
  end
end
