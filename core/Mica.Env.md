# `Mica.Env`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/env.ex#L1)

The one place that names the OTP application whose config Mica reads.

Code outside `config/` and tests reads and writes application config through
this module instead of calling `Application.*_env(:mica, ...)` directly, so
renaming the application only changes `@app` here. The credo check
`Credo.Check.Warning.MicaEnvAccess` enforces this.

Compile-time reads use the `compile_env/2` macro, which keeps the release
check that the value did not change between compile time and runtime:

    require Mica.Env
    @policy_urls Mica.Env.compile_env(:policy_urls)

# `app`

# `compile_env`
*macro* 

# `fetch!`

# `get`

# `put`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
