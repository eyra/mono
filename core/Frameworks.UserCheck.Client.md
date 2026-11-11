# `Frameworks.UserCheck.Client`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/user_check/client.ex#L1)

Behaviour for UserCheck email validation clients.

Implementations:
- `Frameworks.UserCheck.HTTPClient` — real API calls (used in releases)
- `Frameworks.UserCheck.MockClient` — deterministic results (used in dev/test)

# `check_email`

```elixir
@callback check_email(String.t()) ::
  {:ok, Frameworks.UserCheck.ResultModel.t()} | {:error, term()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
