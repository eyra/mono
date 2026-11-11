# `Systems.Account.Auth.Google`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/auth/google.ex#L1)

Google identity provider. Implements `Systems.Account.Auth.Provider` — the
orchestration of "find user by email, attach or refresh satellite"
lives in `Systems.Account.Auth`.

Whether a Google sign-in produces a researcher or a participant
depends on the signup flow the user came from. The Google callback
plug passes `%{creator: creator?}` as `register_overrides` to
`Systems.Account.Auth.authenticate/3`; the orchestrator merges it on top of
this module's `user_attrs/1` output when a brand-new Account.User
is registered.

# `routes`
*macro* 

---

*Consult [api-reference.md](api-reference.md) for complete listing*
