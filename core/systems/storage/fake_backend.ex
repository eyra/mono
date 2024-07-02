defmodule Systems.Storage.FakeBackend do
  @behaviour Systems.Storage.Backend

  def store(_endpoint, data, _meta_data) do
    IO.puts("fake store: #{data}")
    :ok
  end

  def list_files(_endpoint) do
    {:ok, []}
  end
end
