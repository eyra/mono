defmodule Systems.Storage.FakeBackend do
  @behaviour Systems.Storage.Backend

  def store(_endpoint, _panel_info, data, _meta_data) do
    IO.puts("fake store: #{data}")
    :ok
  end
end
