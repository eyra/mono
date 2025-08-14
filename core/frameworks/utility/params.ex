defmodule Frameworks.Utility.Params do
  @moduledoc """
  Utilities for consistent parameter parsing.
  """

  @doc "Safely parse boolean params from strings like 'true', '1', etc."
  def parse_bool_param(params, key, default \\ false) when is_map(params) do
    case Map.get(params, key) do
      nil ->
        default

      val when is_boolean(val) ->
        val

      val when is_binary(val) ->
        normalized = val |> String.downcase() |> String.trim()
        normalized in ["true", "1"]

      _ ->
        false
    end
  end
end
