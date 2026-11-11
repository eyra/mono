# `Mica.Persister`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/persister.ex#L1)

# `t`

```elixir
@type t() :: term()
```

All the types that implement this protocol.

# `save`

```elixir
@spec save(any(), map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
