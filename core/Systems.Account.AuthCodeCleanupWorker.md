# `Systems.Account.AuthCodeCleanupWorker`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/auth_code_cleanup_worker.ex#L1)

Scheduled Oban worker that prunes auth_codes past their validity window,
and the rate counters whose window has ended.

`Account.Public.generate_otp/2` deletes prior codes for the same email when a
new one is requested, but codes for emails that never come back accumulate.
After the validity window they are filtered out by `active_query/1`, so this
worker removes those rows to keep the table bounded. The sign-in code limits
(`Account.AuthCodeLimits`) fill most rate counters, so the same run prunes
those.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
