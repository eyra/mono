# `Systems.Storage.BuiltIn.Backend`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/storage/builtin/backend.ex#L1)

# `check_upload_path!`

Refuses to start while LocalFS donations from an earlier version are still in
`upload_path` (see `BuiltIn.LocalFS.check_upload_path!/2`). Runs at application
start, not in the runtime config: `prod-migrate` evaluates that config without
the S3 settings, so it would look like LocalFS.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
