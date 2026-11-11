# `Systems.BFF.Page`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/bff/page.ex#L1)

A page the BFF serves: the blocks it shows the signed-in `user`, in order.

# `blocks`

```elixir
@callback blocks(user :: Systems.Account.User.t()) :: [struct()]
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
