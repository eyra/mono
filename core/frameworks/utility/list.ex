defmodule Frameworks.Utility.List do
  def append_if(list, term, true), do: append(list, term)
  def append_if(list, _element, _), do: list
  def append_if(list, nil), do: list
  def append_if(list, term), do: append(list, term)

  def append(list, closure) when is_function(closure, 0), do: list ++ [closure.()]
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
