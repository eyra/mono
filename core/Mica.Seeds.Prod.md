# `Mica.Seeds.Prod`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/seeds/prod.ex#L1)

Seeds for production (AWS).

Intentionally empty. Production never seeds accounts: real users
register via the normal signup flow, and admin/service accounts
are provisioned manually via the remote console. The `:e2e`
feature flag is off in prod, so `/api/e2e/bootstrap` is rejected
and no test fixtures can be created.

All operations must be idempotent.

# `seed`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
