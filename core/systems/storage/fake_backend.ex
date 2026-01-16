defmodule Systems.Storage.FakeBackend do
  @behaviour Systems.Storage.Backend

  @impl true
  def store(_endpoint, data, _meta_data) do
    IO.puts("fake store: #{data}")
    :ok
  end

  @impl true
  def list_files(_endpoint) do
    {:ok, []}
  end

  @impl true
  def delete_files(_endpoint) do
    :ok
  end

  @impl true
  def connected?(_endpoint) do
    false
  end

  @impl true
  def filename(%{"identifier" => identifier}) do
    identifier
    |> Enum.map_join("_", fn [key, value] -> "#{key}=#{value}" end)
    |> then(&"#{&1}.json")
  end
end
