# `MicaWeb.Cldr.Number.Transliterate`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/cldr.ex#L1)

Transliteration for digits and separators.

Transliterating a string is an expensive business.  First the string has to
be exploded into its component graphemes.  Then for each grapheme we have
to map to the equivalent in the other `{locale, number_system}`.  Then we
have to reassemble the string.

Effort is made to short circuit where possible. Transliteration is not
required for any `{locale, number_system}` that is the same as `{"en",
"latn"}` since the implementation uses this combination for the placeholders during
formatting already. When short circuiting is possible (typically the en-*
locales with "latn" number_system - the total number of short circuited
locales is 211 of the 537 in CLDR) the overall number formatting is twice as
fast than when formal transliteration is required.

### Configuring precompilation of digit transliterations

This module includes `Cldr.Number.Transliterate.transliterate_digits/3` which transliterates
digits between number systems.  For example from :arabic to :latn.  Since generating a
transliteration map is slow, pairs of transliterations can be configured so that the
transliteration map is created at compile time and therefore speeding up transliteration at
run time.

To configure these transliteration pairs, add the to the `use Cldr` configuration
in a backend module:

    defmodule MyApp.Cldr do
      use Cldr,
      locale: ["en", "fr", "th"],
      default_locale: "en",
      precompile_transliterations: [{:latn, :thai}, {:arab, :thai}]
    end

Where each tuple in the list configures one transliteration map.  In this example, two maps are
configured: from `:latn` to `:thai` and from `:arab` to `:thai`.

A list of configurable number systems is returned by `Cldr.Number.System.numeric_systems/0`.

If a transliteration is requested between two number pairs that have not been configured for
precompilation, a warning is logged.

# `transliterate`

```elixir
@spec transliterate(
  String.t(),
  Cldr.LanguageTag.t() | Cldr.Locale.locale_name(),
  Cldr.Number.System.system_name() | Cldr.Number.System.types(),
  map() | Keyword.t()
) :: String.t() | {:error, {module(), String.t()}}
```

Transliterates from latin digits to another number system's digits.

Transliterates the latin digits 0..9 to their equivalents in
another number system. Also transliterates the decimal and grouping
separators as well as the plus, minus and exponent symbols. Any other character
in the string will be returned "as is".

## Arguments

* `sequence` is the string to be transliterated.

* `locale` is any known locale, defaulting to `MicaWeb.Cldr.get_locale/0`.

* `number_system` is any known number system. If expressed as a `string` it
  is the actual name of a known number system. If epressed as an `atom` it is
  used as a key to look up a number system for the locale (the usual keys are
  `:default` and `:native` but :traditional and :finance are also part of the
  standard). See `MicaWeb.Cldr.Number.System.number_systems_for/1` for a locale to
  see what number system types are defined. The default is `:default`.

For available number systems see `Cldr.Number.System.number_systems/0`
and `MicaWeb.Cldr.Number.System.number_systems_for/1`.  Also see
`MicaWeb.Cldr.Number.Symbol.number_symbols_for/1`.

## Examples

    iex> MicaWeb.Cldr.Number.Transliterate.transliterate("123556")
    "123556"

    iex> MicaWeb.Cldr.Number.Transliterate.transliterate("123,556.000", "fr", :default)
    "123 556,000"

    iex> MicaWeb.Cldr.Number.Transliterate.transliterate("123556", "th", :default)
    "123556"

    iex> MicaWeb.Cldr.Number.Transliterate.transliterate("123556", "th", "thai")
    "๑๒๓๕๕๖"

    iex> MicaWeb.Cldr.Number.Transliterate.transliterate("123556", "th", :native)
    "๑๒๓๕๕๖"

    iex> MicaWeb.Cldr.Number.Transliterate.transliterate("Some number is: 123556", "th", "thai")
    "Some number is: ๑๒๓๕๕๖"

# `transliterate!`

# `transliterate_digits`

```elixir
@spec transliterate_digits(
  String.t(),
  Cldr.Number.System.system_name(),
  Cldr.Number.System.system_name()
) :: String.t()
```

Transliterates digits from one number system to another number system

* `digits` is binary representation of a number

* `from_system` and `to_system` are number system names in atom form.  See
`Cldr.Number.System.numeric_systems/0` for available number systems.

## Example

    iex> MicaWeb.Cldr.Number.Transliterate.transliterate_digits "٠١٢٣٤٥٦٧٨٩", :arab, :latn
    "0123456789"

---

*Consult [api-reference.md](api-reference.md) for complete listing*
