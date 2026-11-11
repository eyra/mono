# `Frameworks.UserCheck.MockClient`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/user_check/mock_client.ex#L1)

Deterministic mock client for dev and test environments.

Returns predictable results based on email prefix patterns:
- `disposable@*` → disposable: true
- `role@*` → role_account: true
- `blocklisted@*` → blocklisted: true
- `nomx@*` → mx: false
- `spam@*` → spam: true
- `typo@gmial.com` → did_you_mean: "typo@gmail.com"
- Everything else → valid email, all checks pass

---

*Consult [api-reference.md](api-reference.md) for complete listing*
