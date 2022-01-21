defmodule Frameworks.Utility.List do
  def append_if(list, false, _element), do: list
  def append_if(list, true, element), do: append(list, element)
  def append(list, element), do: list ++ [element]

  def insert_at_every(list, every, fun) do
    list_size = Enum.count(list)

    list
    |> Enum.with_index()
    |> Enum.flat_map(fn {x, i} ->
      if rem(i, every) == every - 1 and i < list_size - 1 do
        [x, fun.()]
      else
        [x]
      end
    end)
  end
end
