# `Systems.Assignment.Template.Flags`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/assignment/template.ex#L32)

A macro for creating flag structs that control feature availability.

This module provides a macro that generates flag structs with opt-in behavior:
- By default, all flags are disabled (false)
- Use `opt_in: [list_of_flags]` to enable specific flags
- `opt_out` is deprecated but still supported with warnings

## Usage

    defmodule MyFlags do
      use Systems.Assignment.Template.Flags, [:feature_a, :feature_b, :feature_c]
    end

    # Create with all flags disabled (default)
    flags = MyFlags.new()

    # Create with specific flags enabled
    flags = MyFlags.new(opt_in: [:feature_a, :feature_c])

---

*Consult [api-reference.md](api-reference.md) for complete listing*
