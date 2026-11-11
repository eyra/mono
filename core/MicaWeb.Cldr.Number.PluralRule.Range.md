# `MicaWeb.Cldr.Number.PluralRule.Range`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/cldr.ex#L1)

Implements plural rules for ranges

# `plural_rule`

```elixir
@spec plural_rule(
  first :: Cldr.Number.PluralRule.plural_type(),
  last :: Cldr.Number.PluralRule.plural_type(),
  locale :: Cldr.Locale.locale_name() | Cldr.LanguageTag.t()
) :: Cldr.Number.PluralRule.plural_type() | {:error, {module(), String.t()}}
```

Returns a final plural type for a start-of-range plural
type, an end-of-range plural type and a locale.

## Arguments

* `first` is a plural type for the start of a range

* `last` is a plural type for the end of a range

* `locale` is any `Cldr.LanguageTag.t` or a language name
  (not locale name)

## Example

    iex> MicaWeb.Cldr.Number.PluralRule.Range.plural_rule :other, :few, "ar"
    :few

---

*Consult [api-reference.md](api-reference.md) for complete listing*
