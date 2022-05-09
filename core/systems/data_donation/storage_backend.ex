defmodule Systems.DataDonation.StorageBackend do
  @callback store(
              storage_info :: map(),
              vm :: map(),
              data :: binary()
            ) :: nil
end
