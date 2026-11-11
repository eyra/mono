# `MicaWeb.Cldr.Number.System`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/cldr.ex#L1)

# `number_system_for`

```elixir
@spec number_system_for(
  Cldr.Locale.locale_reference(),
  Cldr.Number.System.system_name()
) ::
  {:ok, [atom()]} | {:error, {module(), String.t()}}
```

Returns the actual number system from a number system type.

* `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by ``Cldr.Locale.new!/2``

* `system_name` is any number system name returned by
  `Cldr.known_number_systems/0` or a number system type
  returned by `Cldr.known_number_system_types/0`

This function will decode a number system type into the actual
number system.  If the number system provided can't be decoded
it is returned as is.

## Examples

    iex> MicaWeb.Cldr.Number.System.number_system_for "th", :latn
    {:ok, %{digits: "0123456789", type: :numeric}}

    iex> MicaWeb.Cldr.Number.System.number_system_for "en", :default
    {:ok, %{digits: "0123456789", type: :numeric}}

    iex> MicaWeb.Cldr.Number.System.number_system_for "he", :traditional
    {:ok, %{rules: "hebrew", type: :algorithmic}}

    iex> MicaWeb.Cldr.Number.System.number_system_for "en", :native
    {:ok, %{digits: "0123456789", type: :numeric}}

    iex> MicaWeb.Cldr.Number.System.number_system_for "en", :finance
    {
      :error,
      {Cldr.UnknownNumberSystemError,
        "The number system :finance is unknown for the locale named :en. Valid number systems are %{default: :latn, native: :latn}"}
    }

# `number_system_from_locale`

```elixir
@spec number_system_from_locale(Cldr.Locale.locale_reference()) ::
  Cldr.Number.System.system_name() | {:error, {module(), String.t()}}
```

Returns the number system from a language tag or
locale name.

## Arguments

* `locale` is any language tag returned be `Cldr.Locale.new/2`
  or a locale name in the list returned by `Cldr.known_locale_names/1`

## Returns

* A number system name as an atom

## Examples

    iex> MicaWeb.Cldr.Number.System.number_system_from_locale "en-US-u-nu-thai"
    :thai

    iex> MicaWeb.Cldr.Number.System.number_system_from_locale "en-US"
    :latn

# `number_system_names_for`

```elixir
@spec number_system_names_for(Cldr.Locale.locale_reference()) ::
  {:ok, [atom()]} | {:error, {module(), String.t()}}
```

Returns the number systems available for a locale
or `{:error, message}` if the locale is not known.

* `locale` is any valid locale name returned by `MicaWeb.Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by `MicaWeb.Cldr.Locale.new!/1`

## Examples

    iex> MicaWeb.Cldr.Number.System.number_system_names_for "en"
    {:ok, [:latn]}

    iex> MicaWeb.Cldr.Number.System.number_system_names_for "zz"
    {:error, {Cldr.InvalidLanguageError, "The language \"zz\" is invalid"}}

# `number_system_names_for!`

# `number_system_types_for`

# `number_systems_for`

```elixir
@spec number_systems_for(Cldr.Locale.locale_reference()) ::
  {:ok, map()} | {:error, {module(), String.t()}}
```

Returns the number systems available for a locale
or `{:error, message}` if the locale is not known.

* `locale` is any valid locale name returned by `MicaWeb.Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by `MicaWeb.Cldr.Locale.new!/1`

## Examples

    iex> MicaWeb.Cldr.Number.System.number_systems_for "en"
    {:ok, %{default: :latn, native: :latn}}

    iex> MicaWeb.Cldr.Number.System.number_systems_for "th"
    {:ok, %{default: :latn, native: :thai}}

    iex> MicaWeb.Cldr.Number.System.number_systems_for "zz"
    {:error, {Cldr.InvalidLanguageError, "The language \"zz\" is invalid"}}

# `number_systems_for!`

# `number_systems_like`

```elixir
@spec number_systems_like(
  Cldr.Locale.locale_reference(),
  Cldr.Number.System.system_name()
) ::
  {:ok, list()} | {:error, {module(), String.t()}}
```

# `system_name_from`

```elixir
@spec system_name_from(
  Cldr.Number.System.system_name(),
  Cldr.Locale.locale_reference()
) ::
  {:ok, Cldr.Number.System.system_name()} | {:error, {module(), String.t()}}
```

Returns a number system name for a given locale and number system reference.

* `system_name` is any number system name returned by
  `MicaWeb.Cldr.known_number_systems/0` or a number system type
  returned by `MicaWeb.Cldr.known_number_system_types/0`

* `locale` is any valid locale name returned by `MicaWeb.Cldr.known_locale_names/0`
  or a `Cldr.LanguageTag` struct returned by `MicaWeb.Cldr.Locale.new!/1`

Number systems can be references in one of two ways:

* As a number system type such as :default, :native, :traditional and
  :finance. This allows references to a number system for a locale in a
  consistent fashion for a given use

* WIth the number system name directly, such as :latn, :arab or any of the
  other 70 or so

This function dereferences the supplied `system_name` and returns the
actual system name.

## Examples

    ex> MicaWeb.Cldr.Number.System.system_name_from(:default, "en")
    {:ok, :latn}

    iex> MicaWeb.Cldr.Number.System.system_name_from("latn", "en")
    {:ok, :latn}

    iex> MicaWeb.Cldr.Number.System.system_name_from(:native, "en")
    {:ok, :latn}

    iex> MicaWeb.Cldr.Number.System.system_name_from(:nope, "en")
    {
      :error,
      {Cldr.UnknownNumberSystemError, "The number system :nope is unknown"}
    }

Note that return value is not guaranteed to be a valid
number system for the given locale as demonstrated in the third example.

# `to_system`

Converts a number into the representation of
a non-latin number system.

This function converts numbers to a known
number system only, it does not provide number
formatting.

* `number` is a `float`, `integer` or `Decimal`

* `system_name` is any number system name returned by
  `Cldr.known_number_systems/0` or a number system type
  returned by `Cldr.known_number_system_types/0`

There are two types of number systems in CLDR:

* `:numeric` in which the number system defines
  a direct mapping between the latin digits `0..9`
  into a the number system equivalent.  In this case,
` to_system/2` invokes `Cldr.Number.Transliterate.transliterate_digits/3`
  for the given number.

* `:algorithmic` in which the number system
  does not have the same structure as the `:latn`
  number system and therefore the conversion is
  done algorithmically.  For CLDR the algorithm
  is implemented through `Cldr.Rbnf` rulesets.
  These rulesets are considered by CLDR to be
  less rigorous than the `:numeric` number systems
  and caution and testing for a specific use case
  is recommended.

## Examples

    iex> MicaWeb.Cldr.Number.System.to_system 123456, :hebr
    {:ok, "קכ״ג׳תנ״ו"}

    iex> MicaWeb.Cldr.Number.System.to_system 123, :hans
    {:ok, "一百二十三"}

    iex> MicaWeb.Cldr.Number.System.to_system 123, :hant
    {:ok, "一百二十三"}

    iex> MicaWeb.Cldr.Number.System.to_system 123, :hansfin
    {:ok, "壹佰贰拾叁"}

# `to_system!`

Converts a number into the representation of
a non-latin number system. Returns a converted
string or raises on error.

* `number` is a `float`, `integer` or `Decimal`

* `system_name` is any number system name returned by
  `MicaWeb.Cldr.known_number_systems/0` or a number system type
  returned by `MicaWeb.Cldr.known_number_system_types/0`

See `MicaWeb.Cldr.Number.System.to_system/2` for further
information.

## Examples

    iex> MicaWeb.Cldr.Number.System.to_system! 123, :hans
    "一百二十三"

    iex> MicaWeb.Cldr.Number.System.to_system! 123, :hant
    "一百二十三"

    iex> MicaWeb.Cldr.Number.System.to_system! 123, :hansfin
    "壹佰贰拾叁"

---

*Consult [api-reference.md](api-reference.md) for complete listing*
