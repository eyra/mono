# `Systems.Feldspar.DataDonationCleanupWorker`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/feldspar/data_donation_cleanup_worker.ex#L1)

Scheduled Oban worker that cleans up old data donation files.

Deletes files that are older than the configured retention period (default 2 weeks).
This is the only mechanism that deletes local data donation files; delivery keeps them.

Data donation files live on each node's local filesystem, but Oban's Cron plugin only
inserts jobs on the leader node. A job without a `"node"` arg (from cron or the admin
Actions tab) therefore fans out: it inserts one job per connected node into that node's
local storage delivery queue. The `"node"` arg only selects that queue, so a node job
always runs on its own node and cleans its local folder. A node that is disconnected
during the fan-out is cleaned on the next run.

# `fan_out`

Inserts a cleanup job for each of `nodes` into that node's local storage delivery queue.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
