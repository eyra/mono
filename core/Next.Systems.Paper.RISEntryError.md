# `Next.Systems.Paper.RISEntryError`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/paper/ris_entry_error.ex#L1)

Struct representing a parsing error for a specific line in a RIS file.

# `t`

```elixir
@type t() :: %Next.Systems.Paper.RISEntryError{
  content: String.t() | nil,
  line: integer(),
  message: String.t()
}
```

# `from_map`

Creates a RISEntryError from a map with string or atom keys.
Handles both line/message and line_number/message field names.

# `new`

Creates a new RISEntryError

# `to_map`

Converts the struct to a map for JSON encoding

---

*Consult [api-reference.md](api-reference.md) for complete listing*
