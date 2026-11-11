# `Systems.Account.Auth.Email.UserModel`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/auth/email/user_model.ex#L1)

Satellite identity record for email-first signups.

Mirrors the pattern of `Systems.Account.Auth.Google.UserModel`, `Systems.Account.Auth.Apple.UserModel`, etc.
Stores the full UserCheck validation response as JSON at the time of
registration. This record persists as a historical breadcrumb even after
the user activates their account (sets a password, links Google, etc.).

# `changeset`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
