# `Systems.Email.Mailer`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/email/mailer.ex#L1)

# `deliver`

```elixir
@spec deliver(any()) :: no_return()
```

# `deliver_later`

# `deliver_later!`

# `deliver_now`

```elixir
@spec deliver_now(Bamboo.Email.t(), Enum.t()) ::
  {:ok, Bamboo.Email.t()}
  | {:ok, Bamboo.Email.t(), any()}
  | {:error, Exception.t() | String.t()}
```

# `deliver_now!`

```elixir
@spec deliver_now!(Bamboo.Email.t(), Enum.t()) ::
  Bamboo.Email.t() | {Bamboo.Email.t(), any()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
