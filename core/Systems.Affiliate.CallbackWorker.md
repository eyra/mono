# `Systems.Affiliate.CallbackWorker`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/affiliate/callback_worker.ex#L1)

Sends an event to the affiliate's callback URL (`Systems.Affiliate.Public.queue_event/3`).

The job is inserted in the transaction that records the event, so it runs only
after that transaction commits and not at all when it rolls back. The
researcher's server is called outside the transaction and outside the
participant's process.

A participant's events reach the affiliate in the order they were queued, as
when they were sent from the participant's process: a job snoozes while an
earlier job for the same affiliate and user is still waiting or running. A
snoozing job gives its slot in the queue back, so other affiliates'
callbacks don't wait for it.

A callback is sent once, as before: a failed one is logged
(`Systems.Affiliate.Private.callback/1`) and not retried. The researcher's
server being down is not an error of ours, so the job completes.

# `new_event`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
