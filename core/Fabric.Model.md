# `Fabric.Model`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/fabric/model.ex#L1)

# `model`

```elixir
@type model() :: Fabric.LiveComponent.Model.t()
```

# `model_id`

```elixir
@type model_id() :: atom()
```

# `model_id_optional`

```elixir
@type model_id_optional() :: model_id() | nil
```

# `model_list`

```elixir
@type model_list() :: [model()]
```

# `model_list_optional`

```elixir
@type model_list_optional() :: model_list() | nil
```

# `ref`

```elixir
@type ref() :: Fabric.LiveView.RefModel.t() | Fabric.LiveComponent.RefModel.t()
```

# `ref_optional`

```elixir
@type ref_optional() :: ref() | nil
```

# `t`

```elixir
@type t() :: %Fabric.Model{
  children: model_list_optional(),
  parent: ref_optional(),
  self: ref()
}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
