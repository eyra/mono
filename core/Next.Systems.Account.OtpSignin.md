# `Next.Systems.Account.OtpSignin`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/account/otp_signin.ex#L1)

Steps of the email-first OTP sign-in shared by the LiveView pages
(`AuthIdentifyPage`, `AuthCodeVerifyPage` and the redeem step in
`SessionController`) and the native app's JSON calls
(`NativeSigninController`), so both follow the same rules.

# `provider_url`

Where an email that `Account.EmailRouter` sends to an identity provider
continues signing in.

# `resolve_user`

Finds or creates the user behind a verified code. `user_id` is the user the
code was issued to, or nil when the email had no user yet.

A new email normally registers a fresh user. When a provisional user (an
affiliate synth account that never had a real email) is signed in, the
email is linked to that user instead, so completing auth from the
finished-page "Join Panl" CTA doesn't leave a duplicate user behind.

Returns `{:ok, user, first_time?}`; `first_time?` is true for a newly
registered user, who still has to go through onboarding.

# `valid_email?`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
