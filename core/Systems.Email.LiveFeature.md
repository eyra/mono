# `Systems.Email.LiveFeature`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/email/live_feature.ex#L1)

Swallows the `{:delivered_email, email}` message that `Bamboo.TestAdapter`
sends to the delivering process during tests.

The test adapter delivers immediately, in the caller's process. A LiveView
whose handler sends email, directly or through a signal (e.g. accepting a
contribution notifies the participant), then receives that message itself.
Without this stub it crashes with `no function clause matching` in the test
environment.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
