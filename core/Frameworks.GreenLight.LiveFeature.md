# `Frameworks.GreenLight.LiveFeature`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/green_light/_live_feature.ex#L1)

# `get_authorization_context`
*optional* 

```elixir
@callback get_authorization_context(
  Phoenix.LiveView.unsigned_params() | :not_mounted_at_router,
  session :: map(),
  socket :: Phoenix.Socket.t()
) :: integer() | struct() | %{id: :singleton}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
