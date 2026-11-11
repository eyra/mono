# `mix seed`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/seeds/mix/seed.ex#L1)

Runs `Mica.Seeds.seed/0` which executes base seeds plus
environment-specific seeds based on the `:deploy_env` config.

    $ mix seed

All seed operations are idempotent and safe to run multiple times.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
