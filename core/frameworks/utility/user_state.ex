defmodule Frameworks.Utility.UserState do
  def string_value(data, key) do
    Map.get(data, key)
  end

  def integer_value(data, key) do
    if value = Map.get(data, key) do
      try do
        value |> String.to_integer()
      rescue
        ArgumentError -> nil
      end
    else
      nil
    end
  end
end
