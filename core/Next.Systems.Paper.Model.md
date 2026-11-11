# `Next.Systems.Paper.Model`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/paper/paper_model.ex#L1)

# `t`

```elixir
@type t() :: %Next.Systems.Paper.Model{
  __meta__: term(),
  abbreviated_journal: String.t(),
  abstract: String.t(),
  authors: [String.t()],
  date: String.t(),
  doi: String.t(),
  id: term(),
  inserted_at: term(),
  keywords: [String.t()],
  ris: term(),
  sets: term(),
  subtitle: String.t(),
  title: String.t(),
  updated_at: term(),
  version: term(),
  version_id: term(),
  year: String.t()
}
```

# `changeset`

# `citation`

  Generate an APA style citation for a paper. The citation will be in the format:
  [main_author] ([year]) [title] [journal] If the authors are not present, the citation will be marked with a question mark.

  This can be used as identifier for a paper. It is not guaranteed to be unique due to spelling differences in author and journal names.

# `preload_graph`

# `validate`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
