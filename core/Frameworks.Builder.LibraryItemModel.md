# `Frameworks.Builder.LibraryItemModel`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/builder/library_item_model.ex#L1)

An item a builder can add. `required?` is copied onto what is added: only required
items count when deciding whether a participant finished their tasks.

# `t`

```elixir
@type t() :: %Frameworks.Builder.LibraryItemModel{
  description: binary() | nil,
  id: atom() | binary(),
  required?: boolean(),
  tags: [binary()] | nil,
  title: binary(),
  type: atom() | tuple()
}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
