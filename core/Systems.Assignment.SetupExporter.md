# `Systems.Assignment.SetupExporter`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/assignment/setup_exporter.ex#L1)

Serializes the configuration of an assignment for the study setup export.

`metadata/2` is pure: it takes a loaded assignment and returns the
`next-metadata.json` contents together with the assets that contents refers
to. Every `assets/...` path in the map originates from an entry in the asset
list, so the two cannot drift apart.

Whether an asset can actually be fetched is only known while the zip streams,
so the exported documents describe the package from two angles and are
expected to disagree: `next-metadata.json` records the configured setup and
keeps referring to an asset that failed to download, while
`ro-crate-metadata.json` describes the files the package really contains and
leaves that asset out. `export-warnings.json` names every dropped asset and
bridges the two. Assets outside our own content storage are always dropped.

# `entries`

Packmatic entries for the whole export: the metadata document, one entry per
configured asset, the RO-Crate description of the package and a closing
`export-warnings.json`, all nested under `folder`. `name` is the study name
written into the metadata; `folder` is the undated root folder inside the zip.

The warnings document only materializes when an asset was actually skipped;
a clean export carries no `export-warnings.json`.

# `metadata`

# `preload_graph`

# `record_skipped`

Registers an asset that Packmatic could not fetch, so `export-warnings.json`
can report it.

The accumulated list lives in the process dictionary and `stream/3` clears it
before every export. Packmatic reduces the manifest lazily, so the stream must
be consumed in the process that called `stream/3`; otherwise the recorded
failures and the dynamic sources that read them land in different processes.

Returns `:ignore` for the warnings document itself: a clean export drops that
entry, which Packmatic reports as a failure like any other.

# `stream`

Builds the zip stream for the whole export, resetting the skipped-asset list
that `export-warnings.json` and the RO-Crate report on.

The caller must consume the returned stream in the calling process; see
`record_skipped/2`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
