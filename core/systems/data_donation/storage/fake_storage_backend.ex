defmodule Systems.DataDonation.FakeStorageBackend do
  @behaviour Systems.DataDonation.StorageBackend

  def store(_state, _vm, data) do
    IO.puts("fake store: #{data}")
    :ok
  end
end
