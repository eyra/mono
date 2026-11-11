# `Mica.Seeds.Dev`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/seeds/dev.ex#L1)

Seeds for the dev server (Fly).

Intentionally empty. The dev server is publicly reachable, so no
accounts with known credentials are seeded here. Real users register
via the normal signup flow; the E2E service account is bootstrapped
on demand via `/api/e2e/bootstrap` (gated by the `:e2e` feature flag).

All operations must be idempotent.

# `seed`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
