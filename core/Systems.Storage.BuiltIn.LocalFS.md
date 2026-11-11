# `Systems.Storage.BuiltIn.LocalFS`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/storage/builtin/local_fs.ex#L1)

Stores donations on the local filesystem under the configured `root_path`.

The root must not be a statically served folder (such as `upload_path`):
donations are only handed out through `Systems.Storage.Controller`, which
checks access to the endpoint.

# `check_upload_path!`

Raises when `upload_path` still holds endpoint folders (`project_node=<id>`,
or `assignment=<id>` for endpoints created before storage moved to projects).

Earlier versions stored donations there, where they are served without
authentication and left out of the export. Files are never moved in code:
the error names the folders and the commands to move them to `root_path`.

When the default log handler does not use Logger's own formatter (production
logs JSON), the message is also written to stderr as plain text first, so the
commands can be copied as they are.

# `get_root_path`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
