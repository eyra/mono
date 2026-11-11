# `Frameworks.Concept.Presenter`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/concept/presenter.ex#L1)

# `assigns`

```elixir
@type assigns() :: map()
```

# `model`

```elixir
@type model() :: pos_integer() | map() | nil
```

# `page`

```elixir
@type page() :: atom()
```

# `view_model`

```elixir
@callback view_model(page(), model(), assigns()) :: map()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
