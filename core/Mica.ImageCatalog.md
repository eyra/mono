# `Mica.ImageCatalog`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/image_catalog.ex#L1)

# `image_id`

```elixir
@type image_id() :: binary()
```

# `image_info`

```elixir
@type image_info() :: %{
  id: image_id(),
  url: binary(),
  width: pos_integer(),
  height: pos_integer(),
  srcset: binary(),
  blur_hash: nil | binary(),
  attribution: nil | Phoenix.HTML.Safe.t()
}
```

# `image_size`

```elixir
@type image_size() :: {pos_integer(), pos_integer()}
```

# `meta_info`

```elixir
@type meta_info() :: %{
  page: pos_integer(),
  page_size: pos_integer(),
  page_count: non_neg_integer(),
  image_count: non_neg_integer(),
  begin: pos_integer(),
  end: pos_integer()
}
```

# `search_info_result`

```elixir
@type search_info_result() :: %{images: [image_info()], meta: meta_info()}
```

# `search_result`

```elixir
@type search_result() :: %{images: [image_id()], meta: meta_info()}
```

# `url_opts`

```elixir
@type url_opts() :: [width: pos_integer(), height: pos_integer()]
```

# `info`

```elixir
@callback info(image :: image_id(), opts :: url_opts()) :: image_info() | nil
```

Returns the URLs for the given image (if available)

# `random`

```elixir
@callback random(count :: pos_integer()) :: [binary()]
```

# `search`

```elixir
@callback search(query :: binary(), page :: pos_integer(), page_size :: pos_integer()) ::
  search_result()
```

# `search_info`

```elixir
@callback search_info(
  query :: binary(),
  page :: pos_integer(),
  page_size :: pos_integer(),
  opts :: url_opts()
) :: search_info_result()
```

# `image_catalog`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
