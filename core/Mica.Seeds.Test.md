# `Mica.Seeds.Test`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/seeds/test.ex#L1)

Seeds for the test servers (Fly, multiple testN environments).

Intentionally empty. Test servers are publicly reachable, so no
accounts with known credentials are seeded here. The E2E service
account (`e2e@eyra.service`) is created on demand by the Playwright
global-setup via `/api/e2e/bootstrap` (gated by the `:e2e` feature
flag), and the subsequent `/api/e2e/setup` call provisions the
researcher, participant, assignment, and PaNL fixtures.

All operations must be idempotent.

# `seed`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
