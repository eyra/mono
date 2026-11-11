# `MicaWeb.Cldr.Number.Format`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/cldr.ex#L1)

Functions to manage the collection of number patterns defined in Cldr.

Number patterns affect how numbers are interpreted in a localized context.
Here are some examples, based on the French locale. The "." shows where the
decimal point should go. The "," shows where the thousands separator should
go. A "0" indicates zero-padding: if the number is too short, a zero (in the
locale's numeric set) will go there. A "#" indicates no padding: if the
number is too short, nothing goes there. A "¤" shows where the currency sign
will go. The following illustrates the effects of different patterns for the
French locale, with the number "1234.567". Notice how the pattern characters
',' and '.' are replaced by the characters appropriate for the locale.

## Number Pattern Examples

| Pattern	      | Currency	      | Text        |
| ------------- | :-------------: | ----------: |
| #,##0.##	    | n/a	            | 1 234,57    |
| #,##0.###	    | n/a	            | 1 234,567   |
| ###0.#####	  | n/a	            | 1234,567    |
| ###0.0000#	  | n/a	            | 1234,5670   |
| 00000.0000	  | n/a	            | 01234,5670  |
| #,##0.00 ¤	  | EUR	            | 1 234,57 €  |

The number of # placeholder characters before the decimal do not matter,
since no limit is placed on the maximum number of digits. There should,
however, be at least one zero some place in the pattern. In currency formats,
the number of digits after the decimal also do not matter, since the
information in the supplemental data (see Supplemental Currency Data) is used
to override the number of decimal places — and the rounding — according to
the currency that is being formatted. That can be seen in the above chart,
with the difference between Yen and Euro formatting.

Details of the number formats are described in the
[Unicode documentation](http://unicode.org/reports/tr35/tr35-numbers.html#Number_Format_Patterns)

# `all_formats_for`

```elixir
@spec all_formats_for(Cldr.Locale.locale_reference()) ::
  {:ok, %{required(Cldr.Number.System.system_name()) =&gt; map()}}
  | {:error, {module(), String.t()}}
```

Returns the decimal formats defined for a given locale.

## Arguments

* `locale` is any valid locale name returned by
  `MicaWeb.Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by
  `MicaWeb.Cldr.Locale.new!/1`. The default
  is `MicaWeb.Cldr.get_locale/0`.

## Returns

* `{:ok, map}` where map is a map of decimal formats
  keyed by number system or

* `{:error, {exception, message}}`

# `all_formats_for!`

```elixir
@spec all_formats_for!(Cldr.Locale.locale_reference()) ::
  %{required(Cldr.Number.System.system_name()) =&gt; map()} | no_return()
```

Returns the decimal formats defined for a given locale.

## Arguments

* `locale` is any valid locale name returned by
  `MicaWeb.Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by
  `MicaWeb.Cldr.Locale.new!/1`. The default
  is `MicaWeb.Cldr.get_locale/0`.

## Returns

* `{:ok, map}` where map is a map of decimal formats
  keyed by number system or

* raises an exception.

See `MicaWeb.Cldr.Number.Format.Number.Format.all_formats_for/1` for further information.

# `currency_spacing`

```elixir
@spec currency_spacing(
  Cldr.LanguageTag.t() | Cldr.Locale.locale_name(),
  Cldr.Number.System.system_name()
) :: map() | {:error, {module(), String.t()}}
```

Returns the currency space for a given locale and
number system.

# `decimal_format_list`

```elixir
@spec decimal_format_list() :: [Cldr.Number.Format.format()]
```

Returns the list of decimal formats in the configured locales including
the list of locales configured for precompilation in `config.exs`.

This function exists to allow the decimal formatter
to precompile all the known formats at compile time.

## Example

    #=> MicaWeb.Cldr.Number.Format.Format.decimal_format_list
    ["#", "#,##,##0%",
    "#,##,##0.###", "#,##,##0.00¤", "#,##,##0.00¤;(#,##,##0.00¤)",
    "#,##,##0 %", "#,##0%", "#,##0.###", "#,##0.00 ¤",
    "#,##0.00 ¤;(#,##0.00 ¤)", "#,##0.00¤", "#,##0.00¤;(#,##0.00¤)",
    "#,##0 %", "#0%", "#0.######", "#0.00 ¤", "#E0", "%#,##0", "% #,##0",
    "0", "0.000000E+000", "0000 M ¤", "0000¤", "000G ¤", "000K ¤", "000M ¤",
    "000T ¤", "000mM ¤", "000m ¤", "000 Bio'.' ¤", "000 Bln ¤", "000 Bn ¤",
    "000 B ¤", "000 E ¤", "000 K ¤", "000 MRD ¤", "000 Md ¤", "000 Mio'.' ¤",
    "000 Mio ¤", "000 Mld ¤", "000 Mln ¤", "000 Mn ¤", "000 Mrd'.' ¤",
    "000 Mrd ¤", "000 Mr ¤", "000 M ¤", "000 NT ¤", "000 N ¤", "000 Tn ¤",
    "000 Tr ¤", ...]

# `decimal_format_list_for`

```elixir
@spec decimal_format_list_for(Cldr.LanguageTag.t() | Cldr.Locale.locale_name()) ::
  {:ok, [String.t()]} | {:error, {module(), String.t()}}
```

Returns the list of decimal formats for a configured locale.

## Arguments

* `locale` is any valid locale name returned by
  `MicaWeb.Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by
  `MicaWeb.Cldr.Locale.new!/1`. The default
  is `MicaWeb.Cldr.get_locale/0`.

This function exists to allow the decimal formatter to precompile all
the known formats at compile time. Its use is not otherwise recommended.

## Example

    iex> MicaWeb.Cldr.Number.Format.decimal_format_list_for(:en)
    {:ok, ["#,##0%", "#,##0.###", "#,##0.00", "#,##0.00;(#,##0.00)","#E0",
     "0 billion", "0 million", "0 thousand",
     "0 trillion", "00 billion", "00 million", "00 thousand", "00 trillion",
     "000 billion", "000 million", "000 thousand", "000 trillion", "000B", "000K",
     "000M", "000T", "00B", "00K", "00M", "00T", "0B", "0K", "0M", "0T",
     "¤#,##0.00", "¤#,##0.00;(¤#,##0.00)", "¤000B", "¤000K", "¤000M",
     "¤000T", "¤00B", "¤00K", "¤00M", "¤00T", "¤0B", "¤0K", "¤0M", "¤0T",
     "¤ #,##0.00", "¤ #,##0.00;(¤ #,##0.00)", "¤ 000B", "¤ 000K", "¤ 000M",
     "¤ 000T", "¤ 00B", "¤ 00K", "¤ 00M", "¤ 00T", "¤ 0B", "¤ 0K", "¤ 0M", "¤ 0T"]}

# `default_grouping_for`

```elixir
@spec default_grouping_for(Cldr.Locale.locale_reference()) ::
  {:ok, map()} | {:error, {module(), String.t()}}
```

Returns the default grouping for a locale as a map.

## Arguments

* `locale` is any valid locale name returned by
  `MicaWeb.Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by
  `MicaWeb.Cldr.Locale.new!/1`. The default
  is `MicaWeb.Cldr.get_locale/0`.

## Returns

* `{:ok, grouping}` or

* `{:error, {exception, message}}`

## Examples

    iex> MicaWeb.Cldr.Number.Format.default_grouping_for(:en)
    {:ok, %{fraction: %{first: 0, rest: 0}, integer: %{first: 3, rest: 3}}}

# `default_grouping_for!`

```elixir
@spec default_grouping_for!(Cldr.Locale.locale_reference()) ::
  %{
    fraction: %{first: non_neg_integer(), rest: non_neg_integer()},
    integer: %{first: non_neg_integer(), rest: non_neg_integer()}
  }
  | no_return()
```

Returns the default grouping for a locale
or raises on error.

## Arguments

* `locale` is any valid locale name returned by
  `MicaWeb.Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by
  `MicaWeb.Cldr.Locale.new!/1`. The default
  is `MicaWeb.Cldr.get_locale/0`.

## Returns

* `grouping` as a map or

* raises an exception.

## Examples

    iex> MicaWeb.Cldr.Number.Format.default_grouping_for!(:en)
    %{fraction: %{first: 0, rest: 0}, integer: %{first: 3, rest: 3}}

# `formats_for`

```elixir
@spec formats_for(Cldr.LanguageTag.t() | binary(), atom() | String.t()) ::
  {:ok, map()} | {:error, {module(), String.t()}}
```

Return the predfined formats for a given `locale` and `number_system`.

## Arguments

* `locale` is any valid locale name returned by
  `MicaWeb.Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by
  `MicaWeb.Cldr.Locale.new!/1`. The default
  is `MicaWeb.Cldr.get_locale/0`.

* `number_system` is any valid number system or number system type returned
  by `MicaWeb.Cldr.Number.System.number_systems_for/1`.

## Example

    MicaWeb.Cldr.Number.Format.formats_for :fr, :native
    #=> %Cldr.Number.Format{
      accounting: "#,##0.00 ¤;(#,##0.00 ¤)",
      currency: "#,##0.00 ¤",
      percent: "#,##0 %",
      scientific: "#E0",
      standard: "#,##0.###"
      currency_short: [{"1000", [one: "0 k ¤", other: "0 k ¤"]},
       {"10000", [one: "00 k ¤", other: "00 k ¤"]},
       {"100000", [one: "000 k ¤", other: "000 k ¤"]},
       {"1000000", [one: "0 M ¤", other: "0 M ¤"]},
       {"10000000", [one: "00 M ¤", other: "00 M ¤"]},
       {"100000000", [one: "000 M ¤", other: "000 M ¤"]},
       {"1000000000", [one: "0 Md ¤", other: "0 Md ¤"]},
       {"10000000000", [one: "00 Md ¤", other: "00 Md ¤"]},
       {"100000000000", [one: "000 Md ¤", other: "000 Md ¤"]},
       {"1000000000000", [one: "0 Bn ¤", other: "0 Bn ¤"]},
       {"10000000000000", [one: "00 Bn ¤", other: "00 Bn ¤"]},
       {"100000000000000", [one: "000 Bn ¤", other: "000 Bn ¤"]}],
       ...
      }

# `formats_for!`

```elixir
@spec formats_for!(
  Cldr.LanguageTag.t() | Cldr.Locale.locale_name(),
  Cldr.Number.System.system_name()
) ::
  map() | no_return()
```

# `minimum_grouping_digits_for`

```elixir
@spec minimum_grouping_digits_for(Cldr.Locale.locale_reference()) ::
  {:ok, non_neg_integer()} | {:error, {module(), String.t()}}
```

Returns the minimum grouping digits for a locale.

## Arguments

* `locale` is any valid locale name returned by
  `MicaWeb.Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by
  `MicaWeb.Cldr.Locale.new!/1`. The default
  is `MicaWeb.Cldr.get_locale/0`.

## Returns

* `{:ok, minumum_digits}` or

* `{:error, {exception, message}}`

## Examples

    iex> MicaWeb.Cldr.Number.Format.minimum_grouping_digits_for("en")
    {:ok, 1}

# `minimum_grouping_digits_for!`

```elixir
@spec minimum_grouping_digits_for!(Cldr.Locale.locale_reference()) ::
  non_neg_integer() | no_return()
```

Returns the minimum grouping digits for a locale
or raises on error.

## Arguments

* `locale` is any valid locale name returned by
  `MicaWeb.Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by
  `MicaWeb.Cldr.Locale.new!/1`. The default
  is `MicaWeb.Cldr.get_locale/0`.

## Returns

* `minumum_digits` or

* raises an exception.

## Examples

    iex> MicaWeb.Cldr.Number.Format.minimum_grouping_digits_for!("en")
    1

---

*Consult [api-reference.md](api-reference.md) for complete listing*
