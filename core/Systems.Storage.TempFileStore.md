# `Systems.Storage.TempFileStore`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/storage/temp_file_store.ex#L1)

Behaviour for temporary file storage used by data donation.

# `delete`

```elixir
@callback delete(file_id :: String.t()) :: :ok | {:error, term()}
```

# `read`

```elixir
@callback read(file_id :: String.t()) :: {:ok, binary()} | {:error, :not_found | term()}
```

# `size`

```elixir
@callback size(file_id :: String.t()) :: non_neg_integer()
```

# `store`

```elixir
@callback store(data :: binary(), file_id :: String.t()) ::
  {:ok, %{id: String.t(), size: non_neg_integer()}} | {:error, term()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
