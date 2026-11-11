# `Mica.ImageCatalog.Unsplash.Client`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/image_catalog/unsplash.ex#L1)

# `response`

```elixir
@type response() :: {:ok, any()} | {:error, binary()}
```

# `get`

```elixir
@callback get(access_key :: binary(), path :: binary(), query :: keyword()) :: response()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
