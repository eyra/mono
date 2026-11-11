# `Systems.Storage.BuiltIn.Special`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/storage/builtin/special.ex#L1)

# `delete_files`

```elixir
@callback delete_files(folder :: binary()) :: :ok | {:error, atom()}
```

# `list_files`

```elixir
@callback list_files(folder :: binary()) :: list()
```

Lists the files in `folder` as maps with `:path` (relative to the folder),
`:size`, `:timestamp` and `:source` (a Packmatic source, used by the export).

# `store`

```elixir
@callback store(folder :: binary(), identifier :: [tuple()], data :: binary()) ::
  :ok | {:error, term()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
