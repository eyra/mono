defmodule Systems.DataDonation.StorageBackend do
  alias Systems.DataDonation.ToolModel
  @callback store(tool :: ToolModel.t(), data :: binary()) :: nil
end
