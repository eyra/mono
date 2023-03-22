defmodule Frameworks.Utility.Guards do
  def guard_nil(nil, :integer), do: 0
  def guard_nil(number, :integer) when is_number(number), do: number
  def guard_nil(string, :integer) when is_binary(string), do: String.to_integer(string)
end
