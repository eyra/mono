defmodule Systems.Storage.ServiceIds do
  @moduledoc """
  Defines list of supported storage services
  """
  use Core.Enums.Base,
      {:storage_service_ids, [:builtin, :yoda, :aws, :azure]}
end
