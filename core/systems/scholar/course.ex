defmodule Systems.Scholar.Course do
  @moduledoc """
    Defines scholar course using organisation nodes.
  """

  # FIXME POOL Backwards compatible from new organisation node identifier (course) to old pool name format (intentionally ugly code)
  def pool_name(%{identifier: identifier} = _course), do: stringafy(identifier)
  def currency(%{identifier: identifier} = _course), do: stringafy(identifier)

  defp stringafy([_ | _] = identifier) do
    identifier
    |> Enum.map_join("_", &stringafy(&1))
  end

  defp stringafy(":" <> sub_string), do: sub_string
  defp stringafy(term) when is_binary(term), do: term
end
