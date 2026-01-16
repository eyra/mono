defmodule Systems.Storage.Backend do
  @callback store(
              endpoint :: map(),
              data :: binary(),
              meta_data :: map()
            ) :: any()

  @callback list_files(endpoint :: map()) :: {:ok, list()} | {:error, atom()}
  @callback delete_files(endpoint :: map()) :: :ok | {:error, atom()}
  @callback connected?(endpoint :: map()) :: boolean()
  @callback filename(meta_data :: map()) :: String.t()
end
