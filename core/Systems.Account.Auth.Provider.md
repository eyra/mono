# `Systems.Account.Auth.Provider`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/auth/provider.ex#L1)

Behaviour for Identity Provider satellite modules (SURFconext, Google, …).

An implementation owns the satellite Ecto schema (one row per linked
identity) and the proprietary shape of the IdP's `userinfo` payload.
The orchestrator in `Systems.Account.Auth` is the only caller of these
callbacks; it relies on each implementation being thin and stateless
beyond the satellite row.

See `Systems.Account.Auth.Surfconext` and `Systems.Account.Auth.Google` for the canonical implementations.

# `user_attrs`

```elixir
@type user_attrs() :: %{
  :email =&gt; String.t(),
  optional(:displayname) =&gt; String.t(),
  optional(:creator) =&gt; boolean(),
  optional(:confirmed_at) =&gt; NaiveDateTime.t(),
  optional(:verified_at) =&gt; NaiveDateTime.t(),
  optional(:fullname) =&gt; String.t(),
  optional(:title) =&gt; String.t(),
  optional(:photo_url) =&gt; String.t()
}
```

Normalized Account.User attrs derived from a proprietary `userinfo` map.

Keys mirror what `Systems.Account.User.sso_changeset/2` casts — adding
a new key here means widening the cast list there too. `:email` is the
only required key; the rest are optional and may be omitted by an IdP
that doesn't carry them.

# `attach`

```elixir
@callback attach(user :: Systems.Account.User.t(), userinfo :: map()) ::
  {:ok, struct()} | {:error, Ecto.Changeset.t()}
```

Insert a new satellite row linked to `user` from `userinfo`.

# `get`

```elixir
@callback get(user :: Systems.Account.User.t()) :: struct() | nil
```

Return the satellite row for `user`, or `nil` if none exists.

# `refresh`

```elixir
@callback refresh(user :: Systems.Account.User.t(), userinfo :: map()) :: struct()
```

Refresh the satellite row for `user` with the latest `userinfo`. The row MUST exist.

# `user_attrs`

```elixir
@callback user_attrs(userinfo :: map()) :: user_attrs()
```

Translate a proprietary IdP `userinfo` map into normalized user attrs.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
