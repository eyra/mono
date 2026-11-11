# `MicaWeb.Cldr.Number.Symbol`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/cldr.ex#L1)

# `all_decimal_symbols`

Returns a list of all decimal symbols defined
by the locales configured in this backend as
a list.

# `all_decimal_symbols_class`

Returns a list of all decimal symbols defined
by the locales configured in this backend as
a string.

This string can be used as a character class
when builing a regular expression.

# `all_grouping_symbols`

Returns a list of all grouping symbols defined
by the locales configured in this backend as
a list.

# `all_grouping_symbols_class`

Returns a list of all grouping symbols defined
by the locales configured in this backend as
a string.

This string can be used as a character class
when builing a regular expression.

# `number_symbols_for`

```elixir
@spec number_symbols_for(Cldr.LanguageTag.t() | Cldr.Locale.locale_name()) ::
  {:ok, map()} | {:error, {module(), String.t()}}
```

Returns a map of `Cldr.Number.Symbol.t` structs of the number symbols for each
of the number systems of a locale.

## Options

* `locale` is any valid locale name returned by
  `MicaWeb.Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by
  `MicaWeb.Cldr.Locale.new!/1`. The default
  is `MicaWeb.Cldr.get_locale/0`.

## Example:

    iex> MicaWeb.Cldr.Number.Symbol.number_symbols_for(:th)
    {
      :ok,
      %{
        latn: %Cldr.Number.Symbol{
          decimal: %{standard: "."},
          exponential: "E",
          group: %{standard: ","},
          infinity: "∞",
          list: ";",
          minus_sign: "-",
          nan: "NaN",
          per_mille: "‰",
          percent_sign: "%",
          plus_sign: "+",
          superscripting_exponent: "×",
          time_separator: ":"
        },
        thai: %Cldr.Number.Symbol{
          decimal: %{standard: "."},
          exponential: "E",
          group: %{standard: ","},
          infinity: "∞",
          list: ";",
          minus_sign: "-",
          nan: "NaN",
          per_mille: "‰",
          percent_sign: "%",
          plus_sign: "+",
          superscripting_exponent: "×",
          time_separator: ":"
        }
      }
    }

# `number_symbols_for`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
