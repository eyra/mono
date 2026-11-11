# `Mica.Release`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/release.ex#L1)

# `migrate`

Runs the migrations of Mica and the SaaS's systems (`Mica.SaaS.migrations_paths/0`).

# `rollback`

# `seed`

Runs idempotent seeds for the current deploy environment.
Should be invoked from the release startup script after `migrate/0`.

# `seed_test_user`

Seeds a test creator account for Playwright tests.
Only use on dev/test environments, never on production.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
