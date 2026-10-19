defmodule Systems.Storage.BuiltIn.Special do
  @callback store(
              folder :: binary(),
              identifier :: list(tuple()),
              data :: binary()
            ) :: :ok | {:error, term()}

  @doc """
  Lists the files in `folder` as maps with `:path` (relative to the folder),
  `:size`, `:timestamp` and `:source` (a Packmatic source, used by the export).
  """
  @callback list_files(folder :: binary()) :: list()
  @callback delete_files(folder :: binary()) :: :ok | {:error, atom()}
end
