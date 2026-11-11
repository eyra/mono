# `Systems.Account.Auth.Email.RejectionPolicy`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/auth/email/rejection_policy.ex#L1)

Behaviour for email rejection policies.

Given a UserCheck result, decide whether the email should be rejected.
Callers of `Systems.Account.Auth.Email.register/2` can pass a custom policy module
to override the default rejection rules.

# `reject?`

```elixir
@callback reject?(Frameworks.UserCheck.ResultModel.t()) :: :ok | {:error, atom()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
