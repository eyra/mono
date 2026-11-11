# `Systems.Storage.Private`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/storage/_private.ex#L1)

# `allowed_service_ids`

# `build_special`

# `special_info`

# `storage_delivery_queue`

Returns the node-local Oban queue name for storage operations.

Data donation files are stored on the local filesystem, so storage delivery
jobs must be processed by the same node that received the donation.
The queue name is derived from Node.self() to ensure jobs are processed
only by the node that has access to the local filesystem.

`Mica.ObanConfig` starts this node's queue.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
