# `Next.Systems.Paper.ReferenceFileModel`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/paper/reference_file_model.ex#L1)

# `t`

```elixir
@type t() :: %Next.Systems.Paper.ReferenceFileModel{
  __meta__: term(),
  errors: term(),
  file: term(),
  file_id: term(),
  id: String.t(),
  inserted_at: term(),
  papers: term(),
  status: :uploaded | :processed | :failed | :archived,
  updated_at: term()
}
```

# `__struct__`
*struct* 

  The status of the file in terms of processing.
  - `uploaded`: The file has been uploaded but not yet processed.
  - `processed`: The file has been successfully processed, and data has been extracted.
  - `failed`: An error occurred during the processing of the file.
  - `archived`: The file is no longer active but stored for reference.

# `changeset`

# `preload_graph`

# `validate`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
