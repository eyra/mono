# `Systems.Storage.Backend`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/storage/backend.ex#L1)

# `storage_identifier`

```elixir
@type storage_identifier() :: [storage_identifier_entry()]
```

List of identifier entries, e.g. [[:assignment, 1], [:participant, "abc"]]

# `storage_identifier_entry`

```elixir
@type storage_identifier_entry() :: [atom() | storage_identifier_value()]
```

A 2-element list [atom_key, value]

# `storage_identifier_value`

```elixir
@type storage_identifier_value() :: integer() | String.t() | nil
```

Value in a storage identifier entry: integer, string, or nil

# `connected?`

```elixir
@callback connected?(endpoint :: map()) :: boolean()
```

# `delete_files`

```elixir
@callback delete_files(endpoint :: map()) :: :ok | {:error, atom()}
```

# `filename`

```elixir
@callback filename(storage_identifier()) :: String.t()
```

# `list_files`

```elixir
@callback list_files(endpoint :: map()) :: {:ok, list()} | {:error, atom()}
```

# `store`

```elixir
@callback store(endpoint :: map(), data :: binary(), meta_data :: map()) ::
  :ok | {:error, term()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
