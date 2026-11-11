# `MicaWeb.Cldr.Currency`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/cldr.ex#L1)

# `currencies_for_locale`

```elixir
@spec currencies_for_locale(
  Cldr.Locale.locale_reference(),
  only :: Cldr.Currency.filter(),
  except :: Cldr.Currency.filter()
) :: {:ok, map()} | {:error, {module(), String.t()}}
```

Returns a map of the metadata for all currencies for
a given locale.

## Arguments

* `locale` is any valid locale name returned by `MyApp.Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by `MyApp.Cldr.Locale.new!/1`

* `currency_status` is `:all`, `:current`, `:historic`,
  `unannotated` or `:tender`; or a list of one or more status.
  The default is `:all`. See `Cldr.Currency.currency_filter/2`.

## Returns

* `{:ok, currency_map}` or

* `{:error, {exception, reason}}`

## Example

    => MyApp.Cldr.Currency.currencies_for_locale("en")
    {:ok,
      %{
        FJD: %Cldr.Currency{
          cash_digits: 2,
          cash_rounding: 0,
          code: "FJD",
          count: %{one: "Fijian dollar", other: "Fijian dollars"},
          digits: 2,
          from: nil,
          iso_digits: 2,
          name: "Fijian Dollar",
          narrow_symbol: "$",
          rounding: 0,
          symbol: "FJD",
          tender: true,
          to: nil
        },
        SUR: %Cldr.Currency{
          cash_digits: 2,
          cash_rounding: 0,
          code: "SUR",
          count: %{one: "Soviet rouble", other: "Soviet roubles"},
          digits: 2,
          from: nil,
          iso_digits: nil,
          name: "Soviet Rouble",
          narrow_symbol: nil,
          rounding: 0,
          symbol: "SUR",
          tender: true,
          to: nil
        },
        ...
      }}

# `currencies_for_locale!`

```elixir
@spec currencies_for_locale!(
  Cldr.Locale.locale_name() | Cldr.LanguageTag.t(),
  only :: Cldr.Currency.filter(),
  except :: Cldr.Currency.filter()
) :: map() | no_return()
```

Returns a map of the metadata for all currencies for
a given locale and raises on error.

## Arguments

* `locale` is any valid locale name returned by `MyApp.Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by `MyApp.Cldr.Locale.new!/1`

* `currency_status` is `:all`, `:current`, `:historic`,
  `unannotated` or `:tender`; or a list of one or more status.
  The default is `:all`. See `Cldr.Currency.currency_filter/2`.

## Returns

* `{:ok, currency_map}` or

* raises an exception

## Example

    => MyApp.Cldr.Currency.currencies_for_locale!("en")
    %{
      FJD: %Cldr.Currency{
        cash_digits: 2,
        cash_rounding: 0,
        code: "FJD",
        count: %{one: "Fijian dollar", other: "Fijian dollars"},
        digits: 2,
        from: nil,
        iso_digits: 2,
        name: "Fijian Dollar",
        narrow_symbol: "$",
        rounding: 0,
        symbol: "FJD",
        tender: true,
        to: nil
      },
      SUR: %Cldr.Currency{
        cash_digits: 2,
        cash_rounding: 0,
        code: "SUR",
        count: %{one: "Soviet rouble", other: "Soviet roubles"},
        digits: 2,
        from: nil,
        iso_digits: nil,
        name: "Soviet Rouble",
        narrow_symbol: nil,
        rounding: 0,
        symbol: "SUR",
        tender: true,
        to: nil
      },
      ...
    }

# `currency_for_code`

```elixir
@spec currency_for_code(
  Cldr.Currency.currency_code() | Cldr.Currency.t(),
  Keyword.t()
) ::
  {:ok, Cldr.Currency.t()} | {:error, {module(), String.t()}}
```

Returns the currency metadata for the requested currency code.

## Arguments

* `currency_or_currency_code` is a `binary` or `atom` representation
   of an ISO 4217 currency code, or a `%Cldr.Currency{}` struct.

## Options

* `:locale` is any valid locale name returned by `Cldr.known_locale_names/1`
  or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`

## Returns

* A `{:ok, currency}` or

* `{:error, {exception, reason}}`

## Examples

    iex> MicaWeb.Cldr.Currency.currency_for_code("AUD")
    {:ok,
      %Cldr.Currency{
        cash_digits: 2,
        cash_rounding: 0,
        code: "AUD",
        count: %{one: "Australian dollar", other: "Australian dollars"},
        digits: 2,
        iso_digits: 2,
        name: "Australian Dollar",
        narrow_symbol: "$",
        rounding: 0,
        symbol: "A$",
        tender: true
    }}

    iex> MicaWeb.Cldr.Currency.currency_for_code("THB")
    {:ok,
      %Cldr.Currency{
        cash_digits: 2,
        cash_rounding: 0,
        code: "THB",
        count: %{one: "Thai baht", other: "Thai baht"},
        digits: 2,
        iso_digits: 2,
        name: "Thai Baht",
        narrow_symbol: "฿",
        rounding: 0,
        symbol: "THB",
        tender: true
    }}

# `currency_for_code!`
*since 2.14.0* 

```elixir
@spec currency_for_code!(
  Cldr.Currency.currency_code() | Cldr.Currency.t(),
  Keyword.t()
) ::
  Cldr.Currency.t() | no_return()
```

Returns the currency metadata for the requested currency code.

## Arguments

* `currency_or_currency_code` is a `binary` or `atom` representation
   of an ISO 4217 currency code, or a `%Cldr.Currency{}` struct.

## Options

* `:locale` is any valid locale name returned by `Cldr.known_locale_names/1`
  or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`

## Returns

* A `t:Cldr.Current.t/0` or

* raises an exception

## Examples

    iex> MicaWeb.Cldr.Currency.currency_for_code!("AUD")
    %Cldr.Currency{
      cash_digits: 2,
      cash_rounding: 0,
      code: "AUD",
      count: %{one: "Australian dollar", other: "Australian dollars"},
      digits: 2,
      iso_digits: 2,
      name: "Australian Dollar",
      narrow_symbol: "$",
      rounding: 0,
      symbol: "A$",
      tender: true
    }

    iex> MicaWeb.Cldr.Currency.currency_for_code!("THB")
    %Cldr.Currency{
      cash_digits: 2,
      cash_rounding: 0,
      code: "THB",
      count: %{one: "Thai baht", other: "Thai baht"},
      digits: 2,
      iso_digits: 2,
      name: "Thai Baht",
      narrow_symbol: "฿",
      rounding: 0,
      symbol: "THB",
      tender: true
    }

# `currency_from_locale`

Returns the effective currency for a given locale

## Arguments

* `locale` is a `Cldr.LanguageTag` struct returned by
  `Cldr.Locale.new!/2`

## Returns

* A ISO 4217 currency code as an upcased atom

## Examples

    iex> {:ok, locale} = MicaWeb.Cldr.validate_locale("en")
    iex> MicaWeb.Cldr.Currency.currency_from_locale locale
    :USD

    iex> {:ok, locale} = MicaWeb.Cldr.validate_locale("en-AU")
    iex> MicaWeb.Cldr.Currency.currency_from_locale locale
    :AUD

    iex> MicaWeb.Cldr.Currency.currency_from_locale("en-GB")
    :GBP

# `currency_history_for_locale`

```elixir
@spec currency_history_for_locale(Cldr.LanguageTag.t() | Cldr.Locale.locale_name()) ::
  {:ok, map()} | {:error, {module(), String.t()}}
```

Returns a list of historic and the current
currency for a given locale.

## Arguments

* `locale` is any valid locale name returned by `MyApp.Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by `MyApp.Cldr.Locale.new!/1`

## Example

    iex> MyApp.Cldr.Currency.currency_history_for_locale("en")
    {:ok,
        %{
        USD: %{from: ~D[1792-01-01], to: nil},
        USN: %{tender: false},
        USS: %{from: nil, tender: false, to: ~D[2014-03-01]}
      }
    }

# `currency_strings`

```elixir
@spec currency_strings(
  Cldr.Locale.locale_reference(),
  only :: Cldr.Currency.filter(),
  except :: Cldr.Currency.filter()
) :: {:ok, map()} | {:error, {module(), String.t()}}
```

Returns a map that matches a currency string to a
currency code.

A currency string is a localised name or symbol
representing a currency in a locale-specific manner.

## Arguments

* `locale` is any valid locale name returned by `MyApp.Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by `MyApp.Cldr.Locale.new!/1`

* `currency_status` is `:all`, `:current`, `:historic`,
  `unannotated` or `:tender`; or a list of one or more status.
  The default is `:all`. See `Cldr.Currency.currency_filter/2`.

## Returns

* `{:ok, currency_string_map}` or

* `{:error, {exception, reason}}`

## Example

    => MyApp.Cldr.Currency.currency_strings("en")
    {:ok,
     %{
       "mexican silver pesos" => :MXP,
       "sudanese dinar" => :SDD,
       "bad" => :BAD,
       "rsd" => :RSD,
       "swazi lilangeni" => :SZL,
       "zairean new zaire" => :ZRN,
       "guyanaese dollars" => :GYD,
       "equatorial guinean ekwele" => :GQE,
       ...
      }}

# `currency_strings!`

```elixir
@spec currency_strings!(
  Cldr.LanguageTag.t() | Cldr.Locale.locale_name(),
  only :: Cldr.Currency.filter(),
  except :: Cldr.Currency.filter()
) :: map() | no_return()
```

Returns a map that matches a currency string to a
currency code or raises an exception.

A currency string is a localised name or symbol
representing a currency in a locale-specific manner.

## Arguments

* `locale` is any valid locale name returned by `MyApp.Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by `MyApp.Cldr.Locale.new!/1`

* `currency_status` is `:all`, `:current`, `:historic`,
  `unannotated` or `:tender`; or a list of one or more status.
  The default is `:all`. See `Cldr.Currency.currency_filter/2`.

## Returns

* `{:ok, currency_string_map}` or

* raises an exception

## Example

    => MyApp.Cldr.Currency.currency_strings!("en")
    %{
      "mexican silver pesos" => :MXP,
      "sudanese dinar" => :SDD,
      "bad" => :BAD,
      "rsd" => :RSD,
      "swazi lilangeni" => :SZL,
      "zairean new zaire" => :ZRN,
      "guyanaese dollars" => :GYD,
      "equatorial guinean ekwele" => :GQE,
      ...
     }

# `current_currency_from_locale`

Returns the current currency for a given locale.

This function does not consider the `U` extenion
parameters `cu` or `rg`. It is recommended to us
`Cldr.Currency.currency_from_locale/1` in most
circumstances.

## Arguments

* `locale` is any valid locale name returned by `MyApp.Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by `MyApp.Cldr.Locale.new!/1`

## Example

    iex> MyApp.Cldr.Currency.current_currency_from_locale("en")
    :USD

    iex> MyApp.Cldr.Currency.current_currency_from_locale("en-AU")
    :AUD

# `current_territory_currencies`
*since 2.15.0* 

```elixir
@spec current_territory_currencies() :: %{
  required(Cldr.Locale.territory_code()) =&gt; Cldr.Currency.currency_code()
}
```

Returns a mapping from a territory code to its
current currency code.

If a territory has no current currency (like
Antartica, territory code `:AQ`) then no
mapping is returned for that territory.

## Returns

* A map of `{territory_code => Cldr.Currency.t}`

## Example

    iex> MicaWeb.Cldr.Currency.current_territory_currencies()

# `known_currencies`

# `known_currency?`

# `known_currency_code`

```elixir
@spec known_currency_code(Cldr.Currency.currency_code()) ::
  {:ok, Cldr.Currency.currency_code()} | {:error, {module(), String.t()}}
```

Returns a 2-tuple indicating if the supplied currency code is known.

## Arguments

* `currency_code` is a `binary` or `atom` representing an ISO4217
  currency code

## Returns

* `{:ok, currency_code}` or

* `{:error, {exception, reason}}`

## Examples

    iex> MicaWeb.Cldr.Currency.known_currency_code("AUD")
    {:ok, :AUD}

    iex> MicaWeb.Cldr.Currency.known_currency_code("GGG")
    {:error, {Cldr.UnknownCurrencyError, "The currency \"GGG\" is unknown"}}

# `known_currency_code?`

```elixir
@spec known_currency_code?(Cldr.Currency.currency_code()) :: boolean()
```

Returns a boolean indicating if the supplied currency code is known.

## Arguments

* `currency_code` is a `binary` or `atom` representing an ISO4217
  currency code

## Returns

* `true` or `false`

## Examples

    iex> MicaWeb.Cldr.Currency.known_currency_code?("AUD")
    true

    iex> MicaWeb.Cldr.Currency.known_currency_code?("GGG")
    false

    iex> MicaWeb.Cldr.Currency.known_currency_code?(:XCV)
    false

# `known_currency_codes`

```elixir
@spec known_currency_codes() :: [Cldr.Currency.currency_code(), ...]
```

Returns a list of all known currency codes.

## Example

    iex> MicaWeb.Cldr.Currency.known_currency_codes()

# `new`

```elixir
@spec new(Cldr.Currency.currency_code(), map() | Keyword.t()) ::
  {:ok, Cldr.Currency.t()} | {:error, {module(), String.t()}}
```

Returns a `Currency` struct created from the arguments.

## Arguments

* `currency` is a private use currency code in a format defined by
  [ISO4217](https://en.wikipedia.org/wiki/ISO_4217)
  which is `X` followed by two alphanumeric characters.

* `options` is a map of options representing the optional elements of
  the `Cldr.Currency.t` struct.

## Options

* `:name` is the name of the currency. Required.
* `:digits` is the precision of the currency. Required.
* `:symbol` is the currency symbol. Optional.
* `:narrow_symbol` is an alternative narrow symbol. Optional.
* `:round_nearest` is the rounding precision such as `0.05`. Optional.
* `:alt_code` is an alternative currency code for application use.
* `:cash_digits` is the precision of the currency when used as cash. Optional.
* `:cash_rounding_nearest` is the rounding precision when used as cash
  such as `0.05`. Optional.

## Returns

* `{:ok, Cldr.Currency.t}` or

* `{:error, {exception, message}}`

## Example

    iex> MicaWeb.Cldr.Currency.new(:XAE, name: "Custom Name", digits: 0)
    {:ok,
     %Cldr.Currency{
       alt_code: :XAE,
       cash_digits: 0,
       cash_rounding: nil,
       code: :XAE,
       count: %{other: "Custom Name"},
       digits: 0,
       from: nil,
       iso_digits: 0,
       name: "Custom Name",
       narrow_symbol: nil,
       rounding: 0,
       symbol: "XAE",
       tender: false,
       to: nil
     }}
    iex> MyApp.Cldr.Currency.new(:XAH, name: "Custom Name")
    {:error, "Required options are missing. Required options are [:name, :digits]"}
    iex> MicaWeb.Cldr.Currency.new(:XAE, name: "XAE", digits: 0)
    {:error, {Cldr.CurrencyAlreadyDefined, "Currency :XAE is already defined."}}

# `pluralize`

```elixir
@spec pluralize(pos_integer(), atom(), Keyword.t()) ::
  {:ok, String.t()} | {:error, {module(), String.t()}}
```

Returns the appropriate currency display name for the `currency`, based
on the plural rules in effect for the `locale`.

## Arguments

* `number` is an integer, float or `Decimal`

* `currency` is any currency returned by `Cldr.Currency.known_currencies/0`

* `options` is a keyword list of options

## Options

* `locale` is any valid locale name returned by `MyApp.Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by `MyApp.Cldr.Locale.new!/1`. The
  default is `MicaWeb.Cldr.get_locale/0`

## Returns

* `{:ok, plural_string}` or

* `{:error, {exception, message}}`

## Examples

    iex> MicaWeb.Cldr.Currency.pluralize(1, :USD)
    {:ok, "US dollar"}

    iex> MicaWeb.Cldr.Currency.pluralize(3, :USD)
    {:ok, "US dollars"}

    iex> MicaWeb.Cldr.Currency.pluralize(12, :USD, locale: "zh")
    {:ok, "美元"}

    iex> MicaWeb.Cldr.Currency.pluralize(12, :USD, locale: "fr")
    {:ok, "dollars des États-Unis"}

    iex> MicaWeb.Cldr.Currency.pluralize(1, :USD, locale: "fr")
    {:ok, "dollar des États-Unis"}

# `strings_for_currency`

Returns the strings associated with a currency
in a given locale.

## Arguments

* `currency` is an ISO4217 currency code

* `locale` is any valid locale name returned by `MyApp.Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by `MyApp.Cldr.Locale.new!/1`

## Returns

* A list of strings or

* `{:error, {exception, reason}}`

## Example

    iex> MyApp.Cldr.Currency.strings_for_currency(:AUD, "en")
    ...> |> Enum.sort()
    ["a$", "aud", "australian dollar", "australian dollars"]

---

*Consult [api-reference.md](api-reference.md) for complete listing*
