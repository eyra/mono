defmodule Systems.DataDonation.StorageBackend do
  @callback store(participant_id :: binary(), data :: binary()) :: nil
end
