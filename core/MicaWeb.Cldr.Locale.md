# `MicaWeb.Cldr.Locale`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/cldr.ex#L1)

Backend module that provides functions
to define new locales and display human-readable
locale names for presentation purposes.

# `fallback_locale_names`
*since 2.26.0* 

```elixir
@spec fallback_locale_names(Cldr.LanguageTag.t() | Cldr.Locale.locale_reference()) ::
  {:ok, [Cldr.Locale.locale_name(), ...]} | {:error, {module(), String.t()}}
```

Returns the list of fallback locale names, starting
with the provided locale name.

Fallbacks are a list of locate names which can
be used to resolve translation or other localization
data if such localised data does not exist for
this specific locale..

## Arguments

* `locale_name` is any locale name returned by
  `MicaWeb.Cldr.known_locale_names/0`

## Returns

* `{:ok, list_of_locale_names}` or

* `{:error, {exception, reason}}`

## Examples

    iex> MicaWeb.Cldr.Locale.fallback_locale_names(:"fr-CA")
    {:ok, [:"fr-CA", :fr, :und]}

    # Fallbacks are typically formed by progressively
    # stripping variant, territory and script from the
    # given locale name. But not always - there are
    # certain fallbacks that take a different path.

    iex> MicaWeb.Cldr.Locale.fallback_locale_names(:nb)
    {:ok, [:nb, :no, :und]}

# `fallback_locales`
*since 2.26.0* 

```elixir
@spec fallback_locales(Cldr.LanguageTag.t() | Cldr.Locale.locale_reference()) ::
  {:ok, [Cldr.LanguageTag.t(), ...]} | {:error, {module(), String.t()}}
```

Returns the list of fallback locales, starting
with the provided locale name.

Fallbacks are a list of locate names which can
be used to resolve translation or other localization
data if such localised data does not exist for
this specific locale.

## Arguments

* `locale_name` is any locale name returned by
  `MicaWeb.Cldr.known_locale_names/0`

## Returns

* `{:ok, list_of_locales}` or

* `{:error, {exception, reason}}`

## Examples

    MicaWeb.Cldr.Locale.fallback_locales(:"fr-CA")
    => {:ok,
         [#Cldr.LanguageTag<fr-CA [validated]>, #Cldr.LanguageTag<fr [validated]>,
          #Cldr.LanguageTag<und [validated]>]}

    # Fallbacks are typically formed by progressively
    # stripping variant, territory and script from the
    # given locale name. But not always - there are
    # certain fallbacks that take a different path.

    MicaWeb.Cldr.Locale.fallback_locales(:nb))
    => {:ok,
         [#Cldr.LanguageTag<nb [validated]>, #Cldr.LanguageTag<no [validated]>,
          #Cldr.LanguageTag<und [validated]>]}

# `locale_for_territory`
*since 2.26.0* 

```elixir
@spec locale_for_territory(Cldr.Locale.territory_code()) ::
  {:ok, Cldr.LanguageTag.t()} | {:error, {module(), String.t()}}
```

Returns the "best fit" locale for a given territory.

Using the population percentage data from CLDR, the
language most commonly spoken in the given territory
is used to form a locale name which is then validated
against the given backend.

First a territory-specific locale is validated and if
that fails, the base language only is validate.

For example, if the territory is `AU` then then the
language most spoken is "en". First, the locale "en-AU"
is validated and if that fails, "en" is validated.

## Arguments

* `territory` is any ISO 3166 Alpha-2 territory
  code that can be validated by `Cldr.validate_territory/1`

## Returns

* `{:ok, language_tag}` or

* `{:error, {exception, reason}}`

## Examples

  iex> MicaWeb.Cldr.Locale.locale_for_territory(:AU)
  Elixir.MicaWeb.Cldr.validate_locale(:"en-AU")

  iex> MicaWeb.Cldr.Locale.locale_for_territory(:US)
  Elixir.MicaWeb.Cldr.validate_locale(:"en-US")

  iex> MicaWeb.Cldr.Locale.locale_for_territory(:ZZ)
  {:error, {Cldr.UnknownTerritoryError, "The territory :ZZ is unknown"}}

# `locale_from_host`
*since 2.26.0* 

```elixir
@spec locale_from_host(String.t(), Keyword.t()) ::
  {:ok, Cldr.LanguageTag.t()} | {:error, {module(), String.t()}}
```

Returns a "best fit" locale for a host name.

## Arguments

* `host` is any valid host name

* `options` is a keyword list of options. The default
  is `[]`.

## Options

* `:tlds` is a list of territory codes as upper-cased
  atoms that are to be considered as top-level domains.
  See `Cldr.Locale.locale_from_host/2` for the default
  list.

## Returns

* `{:ok, langauge_tag}` or

* `{:error, {exception, reason}}`

## Notes

Certain top-level domains have become associated with content
underlated to the territory for who the domain is registered.
Therefore Google (and perhaps others) do not associate these
TLDs as belonging to the territory but rather are considered
generic top-level domain names.

## Examples

    iex> MicaWeb.Cldr.Locale.locale_from_host "a.b.com.au"
    Elixir.MicaWeb.Cldr.validate_locale(:"en-AU")

    iex> MicaWeb.Cldr.Locale.locale_from_host("a.b.com.tv")
    {:error,
     {Cldr.UnknownLocaleError, "No locale was identified for territory \"tv\""}}

    iex> MicaWeb.Cldr.Locale.locale_from_host("a.b.com")
    {:error,
     {Cldr.UnknownLocaleError, "No locale was identified for territory \"com\""}}

# `new`

# `new!`

# `script_direction_from_locale`
*since 2.37.0* 

Returns the script direction for a locale.

## Arguments

* `language_tag` is any language tag returned by `Cldr.Locale.new/2`
  or any `locale_name` returned by `Cldr.known_locale_names/1`.

## Returns

* The script direction which is either `:ltr` (for left-to-right
  scripts) or `:rtl` (for right-to-left scripts).

## Examples

    iex> MicaWeb.Cldr.Locale.script_direction_from_locale "en-US"
    :ltr

    iex> MicaWeb.Cldr.Locale.script_direction_from_locale :ar
    :rtl

# `territory_from_host`
*since 2.26.0* 

```elixir
@spec territory_from_host(String.t()) ::
  {:ok, Cldr.Locale.territory_code()} | {:error, {module(), String.t()}}
```

Returns the last segment of a host that might
be a territory.

## Arguments

* `host` is any valid host name

## Returns

* `{:ok, territory}` or

* `{:error, {exception, reason}}`

## Examples

    iex> Cldr.Locale.territory_from_host("a.b.com.au")
    {:ok, :AU}

    iex> Cldr.Locale.territory_from_host("a.b.com")
    {:error,
     {Cldr.UnknownLocaleError, "No locale was identified for territory \"com\""}}

# `territory_from_locale`
*since 2.18.2* 

```elixir
@spec territory_from_locale(Cldr.LanguageTag.t() | Cldr.Locale.locale_name()) ::
  Cldr.Locale.territory_code() | {:error, {module(), String.t()}}
```

Returns the territory from a language tag or
locale name.

## Arguments

* `locale` is any language tag returned by
  `MicaWeb.Cldr.Locale.new/1`
  or a locale name in the list returned by
  `MicaWeb.Cldr.known_locale_names/0`

## Returns

* A territory code as an atom

## Examples

    iex> MicaWeb.Cldr.Locale.territory_from_locale "en-US"
    :US

    iex> MicaWeb.Cldr.Locale.territory_from_locale "en-US-u-rg-GBzzzz"
    :GB

# `timezone_from_locale`
*since 2.19.0* 

```elixir
@spec timezone_from_locale(Cldr.LanguageTag.t() | Cldr.Locale.locale_name()) ::
  String.t() | {:error, {module(), String.t()}}
```

Returns the time zone from a language tag or
locale name.

## Arguments

* `locale` is any language tag returned by
  `MicaWeb.Cldr.Locale.new/1`
  or a locale name in the list returned by
  `MicaWeb.Cldr.known_locale_names/0`

## Returns

* A time zone ID as a string or

* `:error` if no time zone can be determined

## Examples

    iex> MicaWeb.Cldr.Locale.timezone_from_locale "en-US-u-tz-ausyd"
    "Australia/Sydney"

---

*Consult [api-reference.md](api-reference.md) for complete listing*
