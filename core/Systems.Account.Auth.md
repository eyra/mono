# `Systems.Account.Auth`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/auth.ex#L1)

Orchestrates federated authentication against an external Identity
Provider (IdP).

An IdP — SURFconext, Google, … — proves the user owns an email address
and hands back a payload of proprietary fields ("userinfo"). Each IdP
is represented in code by a *provider module* that implements the
`Systems.Account.Auth.Provider` behaviour. A provider owns:

  * the satellite Ecto schema for that IdP (a row per linked identity)
  * the IdP-specific shape of `userinfo`

This module owns the flow that is identical across every IdP:

  1. Translate `userinfo` into a normalized Account.User attrs map via
     the provider's `user_attrs/1`.
  2. Locate (or create) the Eyra Account.User by `:email`.
  3. Attach a new satellite row if the user has none, or refresh the
     existing one.

Plugs/controllers call `authenticate/2` and react to the
`{:ok, %{user: ..., first_time?: ...}}` result.

# `result`

```elixir
@type result() :: %{user: Systems.Account.User.t(), first_time?: boolean()}
```

Result of a successful federated authentication.

# `user_attrs`

```elixir
@type user_attrs() :: %{:email =&gt; String.t(), optional(atom()) =&gt; any()}
```

Normalized Account.User attrs returned by `c:Provider.user_attrs/1`.

# `authenticate`

```elixir
@spec authenticate(
  provider :: module(),
  userinfo :: map(),
  register_overrides :: map()
) ::
  {:ok, result()} | {:error, Ecto.Changeset.t()}
```

Authenticate a federated sign-in.

On success returns `{:ok, %{user: user, first_time?: bool}}`. The
`first_time?` flag is `true` iff the Account.User was just created
during this call; callers use it to choose between the
post-registration landing (e.g. onboarding) and the regular
post-signin destination.

`register_overrides` is merged into the provider's `user_attrs/1`
output before registering a brand-new Account.User. Used for
situational data the IdP itself doesn't carry — for example, Google
sign-in passes `%{creator: creator?}` because the same Google
identity can be a researcher or a participant depending on which
signup flow they came from. Has no effect when the user already
exists.

# `authenticate_or_transfer`

# `remove_auth_methods`

# `transfer`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
