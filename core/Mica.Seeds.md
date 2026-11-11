# `Mica.Seeds`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/seeds.ex#L1)

Idempotent seed orchestration.

Seeds are organized by deploy environment. `Base` runs in every environment
and creates records that must exist everywhere (e.g. the Panl pool). Each
environment may have its own additional seed module under `Mica.Seeds.<Env>`.
After those, each system of the SaaS seeds its own records
(`c:Mica.System.seeds/1`).

Triggered after migrations on every deployment via `Mica.Release.seed/0`.
All seed modules must be idempotent — safe to run multiple times.

# `seed`

Runs all seeds for the current deploy environment.

Always runs `Base.seed/0`, then dispatches to the environment-specific
module based on `:deploy_env` from application config, then runs the seeds
of the SaaS's systems.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
