defmodule Frameworks.Utility.List do
  def insert_at_every(list, every, fun) do
    list_size = Enum.count(list)

    list
    |> Enum.with_index
    |> Enum.flat_map(fn {x, i} ->
      if rem(i, every) == every - 1 and i < list_size - 1 do
        [x, fun.()]
      else
        [x]
      end
    end)
  end
end
