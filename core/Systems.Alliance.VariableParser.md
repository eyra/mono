# `Systems.Alliance.VariableParser`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/alliance/variable_parser.ex#L1)

# `parse`

```elixir
@spec parse(binary(), keyword()) ::
  {:ok, [term()], rest, context, line, byte_offset}
  | {:error, reason, rest, context, line, byte_offset}
when line: {pos_integer(), byte_offset},
     byte_offset: non_neg_integer(),
     rest: binary(),
     reason: String.t(),
     context: map()
```

Parses the given `binary` as parse.

Returns `{:ok, [token], rest, context, position, byte_offset}` or
`{:error, reason, rest, context, line, byte_offset}` where `position`
describes the location of the parse (start position) as `{line, offset_to_start_of_line}`.

To column where the error occurred can be inferred from `byte_offset - offset_to_start_of_line`.

## Options

  * `:byte_offset` - the byte offset for the whole binary, defaults to 0
  * `:line` - the line and the byte offset into that line, defaults to `{1, byte_offset}`
  * `:context` - the initial context value. It will be converted to a map

---

*Consult [api-reference.md](api-reference.md) for complete listing*
