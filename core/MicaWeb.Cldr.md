# `MicaWeb.Cldr`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/cldr.ex#L1)

Provides the core functions to retrieve and manage
the CLDR data that supports formatting and localisation.

It provides the core functions to access formatted
CLDR data, set and retrieve a current locale and validate
certain core data types such as locales, currencies and
territories.

# `available_locale_name?`

# `default_locale`

```elixir
@spec default_locale() :: Cldr.LanguageTag.t() | no_return()
```

Returns the default `locale`.

## Example

    iex> MicaWeb.Cldr.default_locale()
    %Cldr.LanguageTag{
      backend: MicaWeb.Cldr,
      canonical_locale_name: "en-001",
      cldr_locale_name: :"en-001",
      language_subtags: [],
      extensions: %{},
      gettext_locale_name: "en_GB",
      language: "en",
      locale: %{},
      private_use: [],
      rbnf_locale_name: :en,
      requested_locale_name: "en-001",
      script: :Latn,
      territory: :"001",
      transform: %{},
      language_variants: []
    }

# `default_territory`

```elixir
@spec default_territory() ::
  Cldr.Locale.territory_code() | {:error, {module(), String.t()}}
```

Returns the default territory when a locale
does not specify one and none can be inferred.

## Example

    iex> MicaWeb.Cldr.default_territory()
    :"001"

# `ellipsis`

```elixir
@spec ellipsis(String.t() | [String.t()], Keyword.t()) ::
  String.t() | {:error, {module(), String.t()}}
```

Add locale-specific ellipsis to a string.

## Arguments

* `string` is any `String.t` or a 2-element list
  of `String.t` between which the ellipsis is inserted.

* `backend` is any module that includes `use Cldr` and therefore
  is a `Cldr` backend module.  The default is `Cldr.default_backend!/0`.
  Note that `Cldr.default_backend!/0` will raise an exception if
  no `:default_backend` is configured under the `:ex_cldr` key in
  `config.exs`.

* `options` is a keyword list of options.

## Options

* `:locale` is any valid locale name returned by `Cldr.known_locale_names/1`.
  The default is `Cldr.get_locale/0`.

* `:location` determines where to place the ellipsis. The options are
  `:after` (the default for a single string argument), `:between`
  (the default and only valid location for an argument that is a list
  of two strings) and `:before`.

* `:format` formats based upon whether the ellipsis
  is inserted between words or sentences. The valid options are
  `:word` or `:sentence`. The default is `:sentence`.

## Examples

    iex> MicaWeb.Cldr.ellipsis("And furthermore")
    "And furthermore…"

    iex> MicaWeb.Cldr.ellipsis(["And furthermore", "there is much to be done"], locale: :ja)
    "And furthermore…there is much to be done"

    iex> MicaWeb.Cldr.ellipsis("And furthermore", format: :word)
    "And furthermore …"

    iex> MicaWeb.Cldr.ellipsis(["And furthermore", "there is much to be done"], locale: :ja, format: :word)
    "And furthermore … there is much to be done"

# `get_locale`

```elixir
@spec get_locale() :: Cldr.LanguageTag.t()
```

Return the current locale to be used for `Cldr` functions that
take an optional locale parameter for which a locale is not supplied.

## Example

    iex> MicaWeb.Cldr.put_locale("pl")
    iex> MicaWeb.Cldr.get_locale()
    %Cldr.LanguageTag{
       backend: Elixir.MicaWeb.Cldr,
       canonical_locale_name: "pl",
       cldr_locale_name: :pl,
       extensions: %{},
       gettext_locale_name: nil,
       language: "pl",
       locale: %{},
       private_use: [],
       rbnf_locale_name: :pl,
       territory: :PL,
       requested_locale_name: "pl",
       script: :Latn,
       transform: %{},
       language_variants: []
     }

# `known_calendars`

# `known_currencies`

# `known_gettext_locale_name`

```elixir
@spec known_gettext_locale_name(String.t()) :: String.t() | false
```

Returns either the Gettext `locale_name` in Cldr format or
`false` based upon whether the locale name is configured in
`Gettext`.

## Arguments

* `locale` is any valid locale name returned by
  `MicaWeb.Cldr.known_gettext_locale_names/0`

## Examples

    iex> MicaWeb.Cldr.known_gettext_locale_name("en")
    "en"

    iex> MicaWeb.Cldr.known_gettext_locale_name("en-SA")
    false

# `known_gettext_locale_name?`

```elixir
@spec known_gettext_locale_name?(String.t()) :: boolean()
```

Returns a boolean indicating if the specified locale
name is configured and available in Gettext.

## Arguments

* `locale` is any valid locale name returned by
  `MicaWeb.Cldr.known_locale_names/0`

## Examples

    iex> MicaWeb.Cldr.known_gettext_locale_name?("en")
    true

    iex> MicaWeb.Cldr.known_gettext_locale_name?("!!")
    false

# `known_gettext_locale_names`

```elixir
@spec known_gettext_locale_names() :: [String.t()]
```

Returns a list of Gettext locale names but in CLDR format with
underscore replaced by hyphen in order to facilitate comparisons
with `Cldr` locale names.

# `known_locale_name`

```elixir
@spec known_locale_name(Cldr.Locale.locale_name()) :: String.t() | false
```

Returns either the `locale_name` or `false` based upon
whether the locale name is configured in `Cldr`.

This is helpful when building a list of `or` expressions
to return the first known locale name from a list.

## Arguments

* `locale` is any valid locale name returned by
  `MicaWeb.Cldr.known_locale_names/0`

## Examples

    iex> MicaWeb.Cldr.known_locale_name(:"en-AU")
    :"en-AU"

    iex> MicaWeb.Cldr.known_locale_name(:"en-SA")
    false

# `known_locale_name?`

```elixir
@spec known_locale_name?(Cldr.Locale.locale_name()) :: boolean()
```

Returns a boolean indicating if the specified locale
name is configured and available in Cldr.

## Arguments

* `locale` is any valid locale name returned by `MicaWeb.Cldr.known_locale_names/0`

## Examples

    iex> MicaWeb.Cldr.known_locale_name?(:en)
    true

    iex> MicaWeb.Cldr.known_locale_name?(:"!!")
    false

# `known_locale_names`

Returns a list of the known locale names.

Known locales are those locales which
are the subset of all CLDR locales that
have been configured for use either
in this module or in `Gettext`.

# `known_number_system_types`

Returns a list of atoms representing the number systems types known to `Cldr`.

## Example

    iex> MicaWeb.Cldr.known_number_system_types()
    [:default, :finance, :native, :traditional]

# `known_number_systems`

# `known_rbnf_locale_name`

```elixir
@spec known_rbnf_locale_name(Cldr.Locale.locale_name()) :: String.t() | false
```

Returns either the RBNF `locale_name` or `false` based upon
whether the locale name is configured in `Cldr`
and has RBNF rules defined.

## Arguments

* `locale` is any valid locale name returned by
  `MicaWeb.Cldr.known_locale_names/0`

## Examples

    iex> MicaWeb.Cldr.known_rbnf_locale_name(:en)
    :en

    iex> MicaWeb.Cldr.known_rbnf_locale_name(:"en-SA")
    false

# `known_rbnf_locale_name?`

```elixir
@spec known_rbnf_locale_name?(Cldr.Locale.locale_name()) :: boolean()
```

Returns a boolean indicating if the specified locale
name is configured and available in Cldr and supports
rules based number formats (RBNF).

## Arguments

* `locale` is any valid locale name returned by `MicaWeb.Cldr.known_locale_names/0`

## Examples

    iex> MicaWeb.Cldr.known_rbnf_locale_name?(:en)
    true

    iex> MicaWeb.Cldr.known_rbnf_locale_name?(:"!!")
    false

# `known_rbnf_locale_names`

```elixir
@spec known_rbnf_locale_names() :: [Cldr.Locale.locale_name()]
```

Returns a list of locale names which have rules-based number
formats (RBNF).

# `known_territories`

# `normalize_lenient_parse`

Normalizes a string by applying transliteration
of common symbols in numbers, currencies and dates

# `put_gettext_locale`
*since 2.38.0* 

```elixir
@spec put_gettext_locale(Cldr.LanguageTag.t()) ::
  {:ok, binary() | nil} | {:error, {module(), String.t()}}
```

Set the current process's Gettext locale from a
`t:Cldr.LanguageTag`.

## Arguments

* `locale` is a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`.

## Returns

* `{:ok, gettext_locale_name}` or

* `{:error, {exception, reason}}`

## Behaviour

1. If the `locale.gettext_locale_name` is `nil` then an error
   is returned.

2. The `gettext` locale for the `gettext_backend` configured for the
   CLDR backend defined by the `t:Cldr.LanguageTag` is set.

## Examples

    iex> import Cldr.LanguageTag.Sigil
    iex> MicaWeb.Cldr.put_gettext_locale(~l"en")
    {:ok, "en"}

    iex> import Cldr.LanguageTag.Sigil
    iex> MicaWeb.Cldr.put_gettext_locale(~l"ru")
    {
      :error,
      {
        Cldr.UnknownLocaleError,
        "Locale TestBackend.Cldr.Locale.new!(\"ru-RU\") does not map to a known gettext locale name"
      }
    }

# `put_locale`

```elixir
@spec put_locale(Cldr.Locale.locale_reference()) ::
  {:ok, Cldr.LanguageTag.t()} | {:error, {module(), String.t()}}
```

Set the current locale to be used for `Cldr` functions that
take an optional locale parameter for which a locale is not supplied.

## Arguments

* `locale` is any valid locale name returned by `MicaWeb.Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag` struct returned by `MicaWeb.Cldr.Locale.new!/1`

See [rfc5646](https://tools.ietf.org/html/rfc5646) for the specification
of a language tag.

## Examples

    iex> MicaWeb.Cldr.put_locale("en")
    {:ok,
     %Cldr.LanguageTag{
       backend: MicaWeb.Cldr,
       canonical_locale_name: "en",
       cldr_locale_name: :en,
       language_subtags: [],
       extensions: %{},
       gettext_locale_name: "en",
       language: "en",
       locale: %{},
       private_use: [],
       rbnf_locale_name: :en,
       requested_locale_name: "en",
       script: :Latn,
       territory: :US,
       transform: %{},
       language_variants: []
     }}

    iex> MicaWeb.Cldr.put_locale("invalid-locale!")
    {:error, {Cldr.LanguageTag.ParseError,
      "Expected a BCP47 language tag. Could not parse the remaining \"!\" starting at position 15"}}

# `quote`

```elixir
@spec quote(String.t(), Keyword.t()) :: String.t() | {:error, {module(), String.t()}}
```

Add locale-specific quotation marks around a string.

## Arguments

* `string` is any valid Elixir string

* `options` is a keyword list of options

## Options

* `locale` is any valid locale name returned by `Cldr.known_locale_names/1`.
  The default is `Cldr.get_locale/0`.

* `:prefer` is one of `:default` or `:variant` with a default of `:default`.
  Some locales have alternative opening and closing quote marks and `:prefer`
  allows selecting a variant should one exist.

## Examples

    iex> MicaWeb.Cldr.quote("Quoted String", locale: :en)
    "“Quoted String”"

    iex> MicaWeb.Cldr.quote("Quoted String", prefer: :variant, locale: :de)
    "‚Quoted String‘"

    iex> MicaWeb.Cldr.quote("Quoted String", locale: :ja)
    "「Quoted String」"

# `unknown_locale_names`

```elixir
@spec unknown_locale_names() :: [Cldr.Locale.locale_name()]
```

Returns a list of the locales names that are configured,
but not known in CLDR.

Since there is a compile-time exception raised if there are
any unknown locales this function should always
return an empty list.

# `validate_calendar`

# `validate_currency`

# `validate_locale`

```elixir
@spec validate_locale(Cldr.Locale.locale_name() | Cldr.LanguageTag.t() | String.t()) ::
  {:ok, Cldr.LanguageTag.t()} | {:error, {module(), String.t()}}
```

Normalise and validate a locale name.

## Arguments

* `locale` is any valid locale name returned by `MicaWeb.Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by `MicaWeb.Cldr.Locale.new!/1`

## Returns

* `{:ok, language_tag}`

* `{:error, reason}`

## Notes

See [rfc5646](https://tools.ietf.org/html/rfc5646) for the specification
of a language tag.

## Examples

    iex> MicaWeb.Cldr.validate_locale(:en)
    {:ok,
    %Cldr.LanguageTag{
      backend: MicaWeb.Cldr,
      canonical_locale_name: "en",
      cldr_locale_name: :en,
      extensions: %{},
      gettext_locale_name: "en",
      language: "en",
      locale: %{},
      private_use: [],
      rbnf_locale_name: :en,
      requested_locale_name: "en",
      script: :Latn,
      territory: :US,
      transform: %{},
      language_variants: []
    }}

    iex> MicaWeb.Cldr.validate_locale MicaWeb.Cldr.default_locale()
    {:ok,
    %Cldr.LanguageTag{
      backend: MicaWeb.Cldr,
      canonical_locale_name: "en-001",
      cldr_locale_name: :"en-001",
      extensions: %{},
      gettext_locale_name: "en_GB",
      language: "en",
      locale: %{},
      private_use: [],
      rbnf_locale_name: :en,
      requested_locale_name: "en-001",
      script: :Latn,
      territory: :"001",
      transform: %{},
      language_variants: []
    }}

    iex> MicaWeb.Cldr.validate_locale("zzz")
    {:error, {Cldr.InvalidLanguageError, "The language \"zzz\" is invalid"}}

# `validate_number_system`

# `validate_number_system_type`

```elixir
@spec validate_number_system_type(String.t() | atom()) ::
  {:ok, atom()} | {:error, {module(), String.t()}}
```

Normalise and validate a number system type.

## Arguments

* `number_system_type` is any number system type returned by
  `Cldr.known_number_system_types/1`

## Returns

* `{:ok, normalized_number_system_type}` or

* `{:error, {exception, message}}`

## Examples

    iex> MicaWeb.Cldr.validate_number_system_type(:default)
    {:ok, :default}

    iex> MicaWeb.Cldr.validate_number_system_type(:traditional)
    {:ok, :traditional}

    iex> MicaWeb.Cldr.validate_number_system_type(:latn)
    {
      :error,
      {Cldr.UnknownNumberSystemTypeError, "The number system type :latn is unknown"}
    }

    iex> MicaWeb.Cldr.validate_number_system_type("bork")
    {
      :error,
      {Cldr.UnknownNumberSystemTypeError, "The number system type \"bork\" is invalid"}
    }

# `validate_territory`

# `with_locale`
*since 2.32.0* 

```elixir
@spec with_locale(Cldr.Locale.locale_reference(), (-&gt; any())) :: any()
```

Execute a function with a locale ensuring that the
current locale is restored after the function.

## Arguments

* `locale` is any valid locale name returned by `Cldr.known_locale_names/1`.

* `fun` is any 0-arity function or function capture.

## Returns

* The value returned by the function `fun/0` or

* `{:error, {exception, reason}}` if the locale is invalid or

* raises an exception if the current locale cannot be
  identified.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
