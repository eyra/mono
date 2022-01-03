defmodule Frameworks.Utility.Guards do
  def guard_nil(number, :integer) do
    case number do
      nil -> 0
      valid -> valid
    end
  end
end
