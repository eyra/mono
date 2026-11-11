# `Systems.Assignment.Template.Flags.Participants`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/assignment/template.ex#L224)

Feature flags for controlling participant management functionality.

Available flags:
- `:expected` - Show expected completion time/duration
- `:language` - Show language selection options
- `:advert_in_pool` - Allow advertising in participant pool
- `:invite_participants` - Enable participant invitation features
- `:recruit_participants` - Enable organic recruitment link (no pre-assigned participant ID)
- `:affiliate` - Show affiliate/partner participant options
- `:paid_slots` - Subject count is managed via paid slot purchasing (Payment tab)

# `t`

```elixir
@type t() :: %Systems.Assignment.Template.Flags.Participants{
  advert_in_pool: boolean(),
  affiliate: boolean(),
  expected: boolean(),
  invite_participants: boolean(),
  language: boolean(),
  language_fixed_nl: boolean(),
  paid_slots: boolean(),
  recruit_participants: boolean()
}
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

    iex> Systems.Assignment.Template.Flags.Participants.new(opt_in: [:flag1, :flag2])
    %Systems.Assignment.Template.Flags.Participants{flag1: true, flag2: true, ...}

    iex> Systems.Assignment.Template.Flags.Participants.new()
    %Systems.Assignment.Template.Flags.Participants{flag1: false, flag2: false, ...}

# `pop`

Access.pop/3 implementation - removes a key and returns {value, new_struct}.
Allows pattern: {value, new_flags} = pop(flags, :flag_name, default_value)

---

*Consult [api-reference.md](api-reference.md) for complete listing*
