# `Mica.Seeds.Local`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/seeds/local.ex#L1)

Seeds for the local developer environment (mix dev, mix test).
All operations must be idempotent.

These accounts use hardcoded, well-known passwords for developer
convenience. They are intentionally NOT seeded on dev/test/staging,
which are publicly reachable Fly deployments where known
credentials would be a security risk.

The E2E service account is bootstrapped on demand via
`/api/e2e/bootstrap` (same flow as prod) and not seeded here.

# `seed`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
