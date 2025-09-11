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

  @doc "Get a trimmed string param when present; returns nil for missing/blank."
  def parse_string_param(params, key) when is_map(params) do
    case Map.get(params, key) do
      nil ->
        nil

      val when is_binary(val) ->
        v = val |> String.trim()
        if v == "", do: nil, else: v

      _ ->
        nil
    end
  end

  def parse_creator(params), do: parse_bool_param(params, "creator")
end
