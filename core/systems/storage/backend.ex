defmodule Systems.Storage.Backend do
  @typedoc "Value in a storage identifier entry: integer, string, or nil"
  @type storage_identifier_value :: integer() | String.t() | nil

  @typedoc "A 2-element list [atom_key, value]"
  @type storage_identifier_entry :: [atom() | storage_identifier_value()]

  @typedoc "List of identifier entries, e.g. [[:assignment, 1], [:participant, \"abc\"]]"
  @type storage_identifier :: [storage_identifier_entry()]

  @callback store(
              endpoint :: map(),
              data :: binary(),
              meta_data :: map()
            ) :: :ok | {:error, term()}

  @callback list_files(endpoint :: map()) :: {:ok, list()} | {:error, atom()}
  @callback delete_files(endpoint :: map()) :: :ok | {:error, atom()}
  @callback connected?(endpoint :: map()) :: boolean()
  @callback filename(storage_identifier()) :: String.t()
end
