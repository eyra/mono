# `Frameworks.UserState`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/user_state.ex#L1)

Helpers for working with scoped user state in LiveViews.

User state is stored as a nested map with namespaces. Each embedded view
can have its own namespace (e.g., `[:manual, 123]`) that scopes its portion
of the global user state.

## Example

Given global user_state:
    %{manual: %{123 => %{chapter_id: 5}}}

And namespace `[:manual, 123]`, the scoped user_state is:
    %{chapter_id: 5}

## Storage Key Format

User state is persisted to localStorage using URI-like keys:
    next://user-{user_id}@{domain}/{path}/{name}

Example: `next://user-2@localhost/assignment/5/crew/5/task`

# `domain`

Returns the domain for storage keys.

# `extract_scoped_value`

Extracts a specific key from scoped user_state.

Uses the namespace from context to scope the user_state before extracting the key.

# `integer_value`

Extracts integer value from user_state map.

# `parse_user_state`

Parses flat localStorage map with URI keys into nested structure.

Filters by user_id and converts keys like:
    "next://user-10@localhost/assignment/5/crew/5/task" => "4"

Into nested structure:
    %{assignment: %{5 => %{crew: %{5 => %{task: 4}}}}}

## Examples

    iex> parse_user_state(%{"next://user-10@localhost/assignment/5/task" => "4"}, 10)
    %{assignment: %{5 => %{task: 4}}}

# `save`

Saves a key/value pair to storage using the configured backend.

Accepts a namespace and key, builds the full storage key, and delegates to the backend.

## Examples

    iex> save(socket, %{id: 2}, [:manual, 123], :chapter, 5)
    # Saves to "next://user-2@localhost/manual/123/chapter" with value 5

# `scope_user_state`

Scopes user_state to a namespace path.

## Examples

    iex> scope_user_state(%{manual: %{123 => %{chapter_id: 5}}}, [:manual, 123])
    %{chapter_id: 5}

    iex> scope_user_state(%{chapter_id: 5}, nil)
    %{chapter_id: 5}

    iex> scope_user_state(%{}, [:manual, 123])
    %{}

# `string_value`

Extracts string value from user_state map.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
