defmodule Systems.Storage.FakeBackend do
  @behaviour Systems.Storage.Backend

  def store(_state, _vm, data) do
    IO.puts("fake store: #{data}")
    :ok
  end
end
