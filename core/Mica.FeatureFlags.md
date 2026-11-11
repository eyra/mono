# `Mica.FeatureFlags`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/feature_flags.ex#L1)

Feature flags. Systems declare the flags they read (`c:Mica.System.feature_flags/0`),
the SaaS sets their defaults (`c:Mica.SaaS.feature_flags/0`), and the app config
(`config :mica, :features`, and `ENABLED_APP_FEATURES` at runtime) has the final say.

A declared flag is off unless the SaaS or the config turns it on; a flag that is
neither declared nor configured is off. A configured name that no system declares
stays in the effective list, with a warning at boot (`warn_undeclared/0`).

# `conf_enabled?`

# `effective`

The effective flags: the SaaS defaults of all declared flags, merged with the app config.

# `feature_enabled?`
*macro* 

# `features_enabled?`
*macro* 

# `require_feature`
*macro* 

# `warn_undeclared`

Logs a warning for every configured flag name that no system declares.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
