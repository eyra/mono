# `Systems.Account.FeaturesModel`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/features_model.ex#L1)

This schema contains features of members.

# `t`

```elixir
@type t() :: %Systems.Account.FeaturesModel{
  __meta__: Ecto.Schema.Metadata.t(),
  birth_year: integer(),
  gender: atom(),
  id: integer() | nil,
  inserted_at: NaiveDateTime.t(),
  study_program_codes: [atom()],
  updated_at: NaiveDateTime.t(),
  user: Systems.Account.User.t() | Ecto.Association.NotLoaded.t() | nil,
  user_id: integer() | nil
}
```

# `get_student_classes`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
