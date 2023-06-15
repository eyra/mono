defmodule Systems.DataDonation.StorageBackend do
  @callback store(
              session :: map(),
              vm :: map(),
              data :: binary()
            ) :: any()
end
