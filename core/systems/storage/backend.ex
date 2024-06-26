defmodule Systems.Storage.Backend do
  @callback store(
              endpoint :: map(),
              data :: binary(),
              meta_data :: map()
            ) :: any()

  @callback list_files(endpoint :: map()) :: {:ok, list()} | {:error, atom()}
end
