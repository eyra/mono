defmodule Systems.Storage.BackendTypes do
  @moduledoc """
  Defines types of external data storage services
  """
  use Core.Enums.Base,
      {:storage_backend_types, [:aws, :azure, :centerdata, :yoda]}
end
