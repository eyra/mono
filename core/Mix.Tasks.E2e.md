# `mix e2e`
[🔗](https://github.com/eyra/mono/blob/main/next/lib/mix/tasks/e2e.ex#L1)

Run Playwright E2E tests in `core/test/e2e/` against any environment.

    mix e2e                     # local (http://localhost:4000)
    mix e2e --env=local         # local
    mix e2e --env=dev           # https://eyra-next-dev.fly.dev
    mix e2e --env=staging       # https://eyra-next-staging.fly.dev
    mix e2e --env=prod          # https://next.eyra.co
    mix e2e --headed            # show browser window
    mix e2e --browser=chromium  # chromium | webkit | firefox (default chromium)
    mix e2e --env=dev panl_onboarding     # filter to one test file

Non-local environments use Infisical for secrets — run
`infisical login` from `core/test/e2e` first if you haven't yet.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
