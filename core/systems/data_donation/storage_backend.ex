defmodule Systems.DataDonation.StorageBackend do
  @callback store(data :: binary()) :: nil
end
