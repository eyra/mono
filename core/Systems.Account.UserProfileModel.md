# `Systems.Account.UserProfileModel`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/user_profile_model.ex#L1)

This schema contains profile related data for members.

# `t`

```elixir
@type t() :: %Systems.Account.UserProfileModel{
  __meta__: Ecto.Schema.Metadata.t(),
  fullname: String.t() | nil,
  id: integer() | nil,
  inserted_at: NaiveDateTime.t(),
  photo_url: String.t() | nil,
  title: String.t() | nil,
  updated_at: NaiveDateTime.t(),
  user: Systems.Account.User.t() | Ecto.Association.NotLoaded.t() | nil,
  user_id: integer() | nil
}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
