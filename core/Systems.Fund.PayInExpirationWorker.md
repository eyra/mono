# `Systems.Fund.PayInExpirationWorker`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/fund/pay_in_expiration_worker.ex#L1)

Sweeper that marks pending pay-in transactions older than 15 minutes as `:failed`.

Runs every minute via Oban cron. The window is short because a pending row
represents an in-flight OPP hosted checkout that the researcher has abandoned
(typically by navigating away or pressing back).

A `:failed` transaction is still upgradable: if a late `completed` webhook
arrives from OPP after the sweep marked it failed (the researcher really did
pay, the webhook was just slow), `Fund.Public.complete_transaction/1` will
promote `:failed → :completed` and book the funds. Only `:completed`
transactions are refused (idempotency).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
