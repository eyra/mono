# `Frameworks.UserCheck.ResultModel`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/user_check/result_model.ex#L1)

Parsed result from the UserCheck email validation API.

Contains the fields relevant for rejection decisions plus the full
raw response for storage and future analysis.

# `t`

```elixir
@type t() :: %Frameworks.UserCheck.ResultModel{
  alias: boolean(),
  blocklisted: boolean(),
  did_you_mean: String.t() | nil,
  disposable: boolean(),
  mx_provider: String.t() | nil,
  public_domain: boolean(),
  raw: map() | nil,
  role_account: boolean(),
  spam: boolean()
}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
