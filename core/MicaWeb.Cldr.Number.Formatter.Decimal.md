# `MicaWeb.Cldr.Number.Formatter.Decimal`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/cldr.ex#L1)

# `metadata!`

# `to_string`

```elixir
@spec to_string(
  Cldr.Math.number_or_decimal(),
  String.t() | Cldr.Number.Format.Meta.t(),
  Keyword.t() | Cldr.Number.Format.Options.t()
) :: {:ok, String.t()} | {:error, {module(), String.t()}}
```

Formats a number according to a decimal format string.

## Arguments

* `number` is an integer, float or Decimal

* `format` is a format string.  See `MicaWeb.Cldr.Number` for further information.

* `options` is a map of options.  See `MicaWeb.Cldr.Number.to_string/2`
  for further information.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
