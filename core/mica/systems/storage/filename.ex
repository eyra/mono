defmodule Systems.Storage.Filename do
  @moduledoc """
  Generates filenames for storage backends.
  """

  @doc """
  Generates a filename from an identifier list.

  Example: assignment=5_task=9.json
  """
  def generate(identifier) do
    identifier
    |> Enum.reject(fn [_key, value] -> is_nil(value) or value == "" end)
    |> Enum.map_join("_", fn [key, value] -> "#{key}=#{value}" end)
    |> then(&"#{&1}.json")
  end

  @doc """
  Generates a unique filename with timestamp.
  """
  def generate_unique(identifier) do
    base = generate(identifier)
    timestamp = System.system_time(:millisecond)
    String.replace(base, ".json", "_#{timestamp}.json")
  end
end
