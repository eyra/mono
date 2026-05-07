defmodule Systems.Storage.BuiltIn.Special do
  @callback store(
              folder :: binary(),
              identifier :: list(tuple()),
              data :: binary()
            ) :: :ok | {:error, term()}

  @callback list_files(folder :: binary()) :: list()
  @callback delete_files(folder :: binary()) :: :ok | {:error, atom()}
end
