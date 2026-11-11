# `Systems.Assignment.Template.Flags.Affiliate`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/assignment/template.ex#L275)

Feature flags for controlling affiliate/partner functionality.
Currently has no flags defined.

# `t`

```elixir
@type t() :: %Systems.Assignment.Template.Flags.Affiliate{}
```

A struct containing boolean flags for controlling feature availability.
Each flag can be true (enabled) or false (disabled).

# `fetch`

Access.fetch/2 implementation - retrieves a flag value by key.
Returns {:ok, value} if key exists, :error otherwise.

# `flags`

```elixir
@spec flags() :: [atom()]
```

Returns the complete list of available flags for this module.
Useful for introspection and validation.

# `get_and_update`

Access.get_and_update/3 implementation - gets current value and updates it.
Allows pattern: get_and_update(flags, :flag_name, fn current -> {current, new_value} end)

# `new`

```elixir
@spec new(keyword()) :: t()
```

Creates a new flags struct with specified options.

## Options

* `:opt_in` - List of flags to enable (recommended)
* `:opt_out` - List of flags to disable (deprecated)

## Examples

    iex> Systems.Assignment.Template.Flags.Affiliate.new(opt_in: [:flag1, :flag2])
    %Systems.Assignment.Template.Flags.Affiliate{flag1: true, flag2: true, ...}

    iex> Systems.Assignment.Template.Flags.Affiliate.new()
    %Systems.Assignment.Template.Flags.Affiliate{flag1: false, flag2: false, ...}

# `pop`

Access.pop/3 implementation - removes a key and returns {value, new_struct}.
Allows pattern: {value, new_flags} = pop(flags, :flag_name, default_value)

---

*Consult [api-reference.md](api-reference.md) for complete listing*
