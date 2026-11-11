# `Systems.Account.SignInHandoff`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/sign_in_handoff.ex#L1)

Takes over the end of an identity-provider sign-in, for example to hand it
to a native app instead of continuing on the site. Systems list their
handoffs in `c:Mica.System.sign_in_handoffs/0`.

The identity-provider flows (their callbacks and the move-your-account
confirm and decline) end through `sign_in/5` and `end_sign_in/4`, which ask
the handoffs in `Mica.SaaS.sign_in_handoffs/0` order before they do what the
site does. Other sign-ins don't ask them.

# `provider`

```elixir
@type provider() :: atom()
```

# `hand_off`

```elixir
@callback hand_off(
  Plug.Conn.t(),
  provider(),
  Systems.Account.User.t(),
  first_time? :: boolean()
) ::
  {:ok, Plug.Conn.t()} | :skip
```

Returns `{:ok, conn}` with the response to send when the handoff takes this
sign-in through `provider`, or `:skip`. `first_time?` is true for a user who
registered with this sign-in.

# `hand_off_unfinished`

```elixir
@callback hand_off_unfinished(Plug.Conn.t(), provider(), :failed | :cancelled) ::
  {:ok, Plug.Conn.t()} | :skip
```

Returns `{:ok, conn}` with the response to send when the handoff takes a
sign-in through `provider` that ended without signing in: `:failed` (the
provider or the registration failed) or `:cancelled` (the user stopped it).

# `end_sign_in`

Ends a sign-in through `provider` that did not sign in (`:failed` or
`:cancelled`): the first handoff that takes it answers, otherwise `otherwise`
does.

# `sign_in`

Ends a sign-in through `provider` that signed `user` in: the first handoff
that takes it answers, otherwise `log_in_user` does.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
