defmodule Frameworks.Utility.EnumHelpers do
  require Frameworks.Utility.EnumHelpers

  defmacro match_id(value) do
    quote do
      &(&1.id ==
          case unquote(value) do
            string when is_binary(string) -> String.to_integer(string)
            int when is_integer(int) -> int
          end)
    end
  end

  defmacro match_by(key, value) do
    quote do
      &(Map.get(&1, unquote(key)) == unquote(value))
    end
  end

  def find_by_id(enumerable, value) do
    Enum.find(enumerable, match_id(value))
  end

  def find_by(enumerable, key, value) do
    Enum.find(enumerable, match_by(key, value))
  end

  def replace_by(enumerable, key, new_struct) do
    index = Enum.find_index(enumerable, match_by(key, new_struct[key]))
    List.replace_at(enumerable, index, new_struct)
  end

  def replace_by_id(enumerable, new_struct) do
    replace_by(enumerable, :id, new_struct)
  end

  defmacro __using__(_) do
    quote do
      import Frameworks.Utility.EnumHelpers
    end
  end
end
