# `MicaWeb.Cldr.Number.Ordinal`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/cldr.ex#L1)

Implements ordinal plural rules for numbers.

# `available_locale_names`

The locale names for which plural rules are defined.

# `known_locale_names`

```elixir
@spec known_locale_names() :: [Cldr.Locale.locale_name(), ...]
```

The configured locales for which plural rules are defined.

Returns the intersection of `MicaWeb.Cldr.known_locale_names/0` and
the locales for which Ordinal plural rules are defined.

There are many `Cldr` locales which don't have their own plural
rules so this list is the intersection of `Cldr`'s configured
locales and those that have rules.

# `plural_rule`

```elixir
@spec plural_rule(
  Cldr.Math.number_or_decimal(),
  Cldr.Locale.locale_name() | Cldr.LanguageTag.t(),
  atom() | pos_integer()
) :: Cldr.Number.PluralRule.plural_type() | {:error, {module(), String.t()}}
```

Return the plural key for a given number in a given locale

Returns which plural key (`:zero`, `:one`, `:two`, `:few`,
`:many` or `:other`) a given number fits into within the
context of a given locale.

Note that these key names should not be interpreted
literally.  For example, the key returned from
`Cldr.Number.Ordinal.plural_rule(0, "en")` is actually
`:other`, not `:zero`.

This key can then be used to format a number, date, time, unit,
list or other content in a plural-sensitive way.

## Arguments

* `number` is any `integer`, `float` or `Decimal`

* `locale` is any locale returned by `Cldr.Locale.new!/2` or any
  `locale_name` returned by `MicaWeb.Cldr.known_locale_names/0`

* `rounding` is one of `[:down, :up, :ceiling, :floor, :half_even, :half_up, :half_down]`.  The
  default is `:half_even`.

## Examples

    iex> MicaWeb.Cldr.Number.Ordinal.plural_rule 0, "fr"
    :other

    iex> MicaWeb.Cldr.Number.Ordinal.plural_rule 1, "en"
    :one

# `plural_rules`

```elixir
@spec plural_rules() :: %{
  required(Cldr.Locale.locale_name()) =&gt; [
    {plural_type :: Cldr.Number.PluralRule.plural_type(),
     plural_rules :: [Cldr.Number.PluralRule.plural_rule(), ...]},
    ...
  ]
}
```

Returns all the plural rules defined in CLDR.

# `plural_rules_for`

```elixir
@spec plural_rules_for(Cldr.Locale.locale_name() | Cldr.LanguageTag.t()) :: [
  {atom(), list()},
  ...
]
```

Return the plural rules for a locale.

## Arguments

* `locale` is any locale returned by `MicaWeb.Cldr.Locale.new!/1` or any
  `locale_name` returned by `MicaWeb.Cldr.known_locale_names/0`

The rules are returned in AST form after parsing.

# `pluralize`

```elixir
@spec pluralize(
  Cldr.Math.number_or_decimal() | Range.t(),
  Cldr.Locale.locale_reference(),
  %{}
) :: any()
```

Pluralize a number using ordinal plural rules
and a substitution map.

## Arguments

* `number` is an integer, float or Decimal or a `Range.t{}`.  When a range, The
  is that in any usage, the start value is strictly less than the end value,
  and that no values are negative. Results for any cases that do not meet
  these criteria are undefined.

* `locale` is any locale returned by `MicaWeb.Cldr.Locale.new!/1` or any
  `locale_name` returned by `MicaWeb.Cldr.known_locale_names/0`

* `substitutions` is a map that maps plural keys to a string.
  The valid substitution keys are `:zero`, `:one`, `:two`,
  `:few`, `:many` and `:other`.

See also `MicaWeb.Cldr.Number.Ordinal.Ordinal.plural_rule/3`.

## Examples

    iex> MicaWeb.Cldr.Number.Ordinal.pluralize 1, :en, %{one: "one"}
    "one"

    iex> MicaWeb.Cldr.Number.Ordinal.pluralize 2, :en, %{one: "one"}
    nil

    iex> MicaWeb.Cldr.Number.Ordinal.pluralize 2, :en, %{one: "one", two: "two"}
    "two"

    iex> MicaWeb.Cldr.Number.Ordinal.pluralize 22, :en, %{one: "one", two: "two", other: "other"}
    "two"

    iex> MicaWeb.Cldr.Number.Ordinal.pluralize Decimal.new(1), :en, %{one: "one"}
    "one"

    iex> MicaWeb.Cldr.Number.Ordinal.pluralize Decimal.new(2), :en, %{one: "one"}
    nil

    iex> MicaWeb.Cldr.Number.Ordinal.pluralize Decimal.new(2), :en, %{one: "one", two: "two"}
    "two"

    iex> MicaWeb.Cldr.Number.Ordinal.pluralize 1..10, "ar", %{one: "one", few: "few", other: "other"}
    "other"

    iex> MicaWeb.Cldr.Number.Ordinal.pluralize 1..10, "en", %{one: "one", few: "few", other: "other"}
    "other"

---

*Consult [api-reference.md](api-reference.md) for complete listing*
