# `Next.Systems.Paper.RISEntry`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/paper/ris_entry.ex#L1)

Struct representing a bibliographic entry from a RIS file.
Used to maintain consistent data structure across the import pipeline.

# `status`

```elixir
@type status() :: :new | :existing | :error
```

# `t`

```elixir
@type t() :: %Next.Systems.Paper.RISEntry{
  abbreviated_journal: String.t() | nil,
  abstract: String.t() | nil,
  authors: [String.t()],
  date: String.t() | nil,
  doi: String.t() | nil,
  error: String.t() | nil,
  journal: String.t() | nil,
  keywords: [String.t()] | nil,
  line_number: integer() | nil,
  pages: String.t() | nil,
  paper_id: integer() | nil,
  status: String.t(),
  subtitle: String.t() | nil,
  title: String.t() | nil,
  volume: String.t() | nil,
  year: String.t() | nil
}
```

# `error`

Creates a new RISEntry for a parsing error.
Accepts either a string or a structured error map.

# `existing_paper`

Creates a new RISEntry for an existing paper

# `from_map`

Creates a RISEntry from a map with atom keys
(as returned by Ecto when loading JSON from database)

# `new_paper`

Creates a new RISEntry for a new paper

# `process_entry_errors`

Processes entries to extract error entries and convert them to RISEntryError structs.
Handles various error formats that may come from RIS parsing.

# `to_map`

Converts the struct to a map for JSON encoding in database

---

*Consult [api-reference.md](api-reference.md) for complete listing*
