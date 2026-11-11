# `MicaWeb.Cldr.DateTime.Format`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/cldr.ex#L1)

Manages the Date, TIme and DateTime formats
defined by CLDR.

The functions in `Cldr.DateTime.Format` are
primarily concerned with encapsulating the
data from CLDR in functions that are used
during the formatting process.

For more information see `Cldr.DateTime.Format`.

# `calendar`

```elixir
@type calendar() :: atom()
```

# `formats`

```elixir
@type formats() :: map()
```

# `calendars_for`

```elixir
@spec calendars_for(Cldr.Locale.locale_reference()) ::
  {:ok, [calendar(), ...]} | {:error, {module(), String.t()}}
```

Returns a list of calendars defined for a given locale.

## Arguments

* `locale` is any locale returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

## Example

    iex> MicaWeb.Cldr.DateTime.Format.calendars_for(:en)
    {:ok, [:buddhist, :chinese, :coptic, :dangi, :ethiopic, :ethiopic_amete_alem,
     :generic, :gregorian, :hebrew, :indian, :islamic, :islamic_civil,
     :islamic_rgsa, :islamic_tbla, :islamic_umalqura, :iso8601, :japanese, :persian, :roc]}

# `common_date_time_format_ids`

```elixir
@spec common_date_time_format_ids() :: [Cldr.DateTime.Format.format_id()]
```

Returns a list of the date_time format IDs that are
available in all known locales.

The format IDs returned by `common_date_time_format_ids/0`
are guaranteed to be available in all known locales,

## Example:

    iex> MicaWeb.Cldr.DateTime.Format.common_date_time_format_ids()
    [:Bh, :Bhm, :Bhms, :E, :EBh, :EBhm, :EBhms, :EHm, :EHms, :Ed, :Eh, :Ehm, :Ehms,
     :Gy, :GyM, :GyMEd, :GyMMM, :GyMMMEd, :GyMMMd, :GyMd, :H, :Hm, :Hms, :Hmsv,
     :Hmv, :Hv, :M, :MEd, :MMM, :MMMEd, :MMMMW, :MMMMd, :MMMd, :Md, :d, :h, :hm,
     :hms, :hmsv, :hmv, :hv, :ms, :y, :yM, :yMEd, :yMMM, :yMMMEd, :yMMMM, :yMMMd,
     :yMd, :yQQQ, :yQQQQ, :yw]

# `common_date_time_format_names`

> This function is deprecated. Use common_date_time_format_ids/0.

# `date_available_formats`

```elixir
@spec date_available_formats(Cldr.Locale.locale_reference(), calendar()) ::
  {:ok, formats()} | {:error, {module(), String.t()}}
```

Returns a map of the available date formats for a
given locale and calendar.

## Arguments

* `locale` is any locale returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

* `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
  The default is `:gregorian`.

## Examples:

    iex> MicaWeb.Cldr.DateTime.Format.date_available_formats(:en)

# `date_formats`

```elixir
@spec date_formats(Cldr.Locale.locale_reference(), calendar()) ::
  {:ok, map()} | {:error, {module(), String.t()}}
```

Returns a map of the standard date formats for a given locale and calendar.

The value of each format type is itself a key into the map returned by
`MicaWeb.Cldr.DateTime.Format.date_time_available_formats/2` which returns the
actual format string.

## Arguments

* `locale` is any locale returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

* `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
  The default is `:gregorian`.

## Examples:

    iex> MicaWeb.Cldr.DateTime.Format.date_formats(:en)
    {:ok,
     %Cldr.Date.Formats{
       short: :yyMd,
       medium: :yMMMd,
       long: :yMMMMd,
       full: :yMMMMEEEEd
     }}

    iex> MicaWeb.Cldr.DateTime.Format.date_formats(:en, :buddhist)
    {:ok,
     %Cldr.Date.Formats{
       short: :GGGGGyMd,
       medium: :GyMMMd,
       long: :GyMMMMd,
       full: :GyMMMMEEEEd
     }}

# `date_time_at_formats`

```elixir
@spec date_time_at_formats(Cldr.Locale.locale_reference(), calendar()) ::
  {:ok, map()} | {:error, {module(), String.t()}}
```

Returns a map of the standard datetime "at" formats for a given
locale and calendar.

An "at" format is one where the datetime is formatted with the
date part separated from the time part by a localized version
of "at".

## Arguments

* `locale` is any locale returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

* `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
  The default is `:gregorian`,

## Examples:

    iex> MicaWeb.Cldr.DateTime.Format.date_time_at_formats(:en)
    {:ok,
     %Cldr.DateTime.Formats{
       short: "{1}, {0}",
       medium: "{1}, {0}",
       long: "{1} 'at' {0}",
       full: "{1} 'at' {0}"
     }}

    iex> MicaWeb.Cldr.DateTime.Format.date_time_at_formats(:en, :buddhist)
    {:ok,
     %Cldr.DateTime.Formats{
       short: "{1}, {0}",
       medium: "{1}, {0}",
       long: "{1} 'at' {0}",
       full: "{1} 'at' {0}"
     }}

# `date_time_available_formats`

```elixir
@spec date_time_available_formats(Cldr.Locale.locale_reference(), calendar()) ::
  {:ok, formats()} | {:error, {module(), String.t()}}
```

Returns a map of the available datetime formats for a
given locale and calendar.

## Arguments

* `locale` is any locale returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

* `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
  The default is `:gregorian`.

## Examples:

    iex> MicaWeb.Cldr.DateTime.Format.date_time_available_formats(:en)
    {:ok,
     %{
       ahmmssz: %{unicode: "h:mm:ss a z", ascii: "h:mm:ss a z"},
       y: "y",
       Hv: "HH'h' v",
       EHm: "E HH:mm",
       EBh: "E h B",
       Bh: "h B",
       Eh: %{unicode: "E h a", ascii: "E h a"},
       hm: %{unicode: "h:mm a", ascii: "h:mm a"},
       GyMEd: "E, M/d/y G",
       Bhms: "h:mm:ss B",
       H: "HH",
       yw: %{
         other: "'week' w 'of' Y",
         one: "'week' w 'of' Y",
         pluralize: :week_of_year
       },
       Ed: "d E",
       Bhm: "h:mm B",
       Gy: "y G",
       GyM: "M/y G",
       ahmmss: %{unicode: "h:mm:ss a", ascii: "h:mm:ss a"},
       M: "L",
       h: %{unicode: "h a", ascii: "h a"},
       yM: "M/y",
       MMMMW: %{
         other: "'week' W 'of' MMMM",
         one: "'week' W 'of' MMMM",
         pluralize: :week_of_month
       },
       GyMMMd: "MMM d, y G",
       yMMMEd: "E, MMM d, y",
       ahmm: %{unicode: "h:mm a", ascii: "h:mm a"},
       Hm: "HH:mm",
       ahmmsszzzz: %{unicode: "h:mm:ss a zzzz", ascii: "h:mm:ss a zzzz"},
       yMMM: "MMM y",
       d: "d",
       Ehm: %{unicode: "E h:mm a", ascii: "E h:mm a"},
       EBhms: "E h:mm:ss B",
       ms: "mm:ss",
       hmsv: %{unicode: "h:mm:ss a v", ascii: "h:mm:ss a v"},
       yQQQ: "QQQ y",
       MMM: "LLL",
       yyMd: "M/d/yy",
       Hmv: "HH:mm v",
       yMMMMd: "MMMM d, y",
       hmv: %{unicode: "h:mm a v", ascii: "h:mm a v"},
       GyMd: "M/d/y G",
       yMd: "M/d/y",
       EHms: "E HH:mm:ss",
       Hms: "HH:mm:ss",
       yMEd: "E, M/d/y",
       hms: %{unicode: "h:mm:ss a", ascii: "h:mm:ss a"},
       MMMEd: "E, MMM d",
       EBhm: "E h:mm B",
       Md: "M/d",
       GyMMM: "MMM y G",
       hv: %{unicode: "h a v", ascii: "h a v"},
       yMMMMEEEEd: "EEEE, MMMM d, y",
       MEd: "E, M/d",
       Ehms: %{unicode: "E h:mm:ss a", ascii: "E h:mm:ss a"},
       yMMMM: "MMMM y",
       yMMMd: "MMM d, y",
       Hmsv: "HH:mm:ss v",
       GyMMMEd: "E, MMM d, y G",
       yQQQQ: "QQQQ y",
       MMMd: "MMM d",
       E: "ccc",
       MMMMd: "MMMM d"
     }}

# `date_time_formats`

```elixir
@spec date_time_formats(Cldr.Locale.locale_reference(), calendar()) ::
  {:ok, map()} | {:error, {module(), String.t()}}
```

Returns a map of the standard datetime formats for a given locale and calendar.

## Arguments

* `locale` is any locale returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

* `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
  The default is `:gregorian`.

## Examples:

    iex> MicaWeb.Cldr.DateTime.Format.date_time_formats(:en)
    {:ok,
     %Cldr.DateTime.Formats{
       short: "{1}, {0}",
       medium: "{1}, {0}",
       long: "{1}, {0}",
       full: "{1}, {0}"
     }}

    iex> MicaWeb.Cldr.DateTime.Format.date_time_formats(:en, :buddhist)
    {:ok,
     %Cldr.DateTime.Formats{
       short: "{1}, {0}",
       medium: "{1}, {0}",
       long: "{1}, {0}",
       full: "{1}, {0}"
     }}

# `date_time_interval_fallback`

```elixir
@spec date_time_interval_fallback(Cldr.Locale.locale_reference(), calendar()) ::
  list() | {:error, {module(), String.t()}}
```

Returns the fallback format for a given
locale and calendar type

## Arguments

* `locale` is any locale returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

* `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
  The default is `:gregorian`.

## Examples:

    iex> MicaWeb.Cldr.DateTime.Format.date_time_interval_fallback(:en, :gregorian)
    [0, " – ", 1]

# `date_time_interval_formats`

```elixir
@spec date_time_interval_formats(Cldr.Locale.locale_reference(), calendar()) ::
  {:ok, formats()} | {:error, {module(), String.t()}}
```

Returns a map of the interval formats for a
given locale and calendar.

## Arguments

* `locale` is any locale returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

* `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
  The default is `:gregorian`.

## Examples:

    iex> MicaWeb.Cldr.DateTime.Format.date_time_interval_formats(:en, :gregorian)
    {:ok,
     %{
       h: %{a: ["h a – ", "h a"], h: ["h – ", "h a"]},
       d: %{d: ["d – ", "d"]},
       y: %{y: ["y – ", "y"]},
       M: %{M: ["M – ", "M"]},
       Bh: %{h: ["h – ", "h B"], B: ["h B – ", "h B"]},
       Bhm: %{
         m: ["h:mm – ", "h:mm B"],
         h: ["h:mm – ", "h:mm B"],
         B: ["h:mm B – ", "h:mm B"]
       },
       Gy: %{y: ["y – ", "y G"], G: ["y G – ", "y G"]},
       GyMMM: %{
         y: ["MMM y – ", "MMM y G"],
         M: ["MMM – ", "MMM y G"],
         G: ["MMM y G – ", "MMM y G"]
       },
       GyMMMEd: %{
         d: ["E, MMM d – ", "E, MMM d, y G"],
         y: ["E, MMM d, y – ", "E, MMM d, y G"],
         M: ["E, MMM d – ", "E, MMM d, y G"],
         G: ["E, MMM d, y G – ", "E, MMM d, y G"]
       },
       GyMMMd: %{
         d: ["MMM d – ", "d, y G"],
         y: ["MMM d, y – ", "MMM d, y G"],
         M: ["MMM d – ", "MMM d, y G"],
         G: ["MMM d, y G – ", "MMM d, y G"]
       },
       GyMd: %{
         d: ["M/d/y – ", "M/d/y G"],
         y: ["M/d/y – ", "M/d/y G"],
         M: ["M/d/y – ", "M/d/y G"],
         G: ["M/d/y G – ", "M/d/y G"]
       },
       H: %{H: ["HH – ", "HH"]},
       Hm: %{m: ["HH:mm – ", "HH:mm"], H: ["HH:mm – ", "HH:mm"]},
       Hmv: %{m: ["HH:mm – ", "HH:mm v"], H: ["HH:mm – ", "HH:mm v"]},
       MEd: %{d: ["E, M/d – ", "E, M/d"], M: ["E, M/d – ", "E, M/d"]},
       MMM: %{M: ["MMM – ", "MMM"]},
       MMMEd: %{
         d: ["E, MMM d – ", "E, MMM d"],
         M: ["E, MMM d – ", "E, MMM d"]
       },
       MMMd: %{d: ["MMM d – ", "d"], M: ["MMM d – ", "MMM d"]},
       Md: %{d: ["M/d – ", "M/d"], M: ["M/d – ", "M/d"]},
       hm: %{
         m: ["h:mm – ", "h:mm a"],
         a: ["h:mm a – ", "h:mm a"],
         h: ["h:mm – ", "h:mm a"]
       },
       hmv: %{
         m: ["h:mm – ", "h:mm a v"],
         a: ["h:mm a – ", "h:mm a v"],
         h: ["h:mm – ", "h:mm a v"]
       },
       yM: %{y: ["M/y – ", "M/y"], M: ["M/y – ", "M/y"]},
       yMEd: %{
         d: ["E, M/d/y – ", "E, M/d/y"],
         y: ["E, M/d/y – ", "E, M/d/y"],
         M: ["E, M/d/y – ", "E, M/d/y"]
       },
       yMMM: %{y: ["MMM y – ", "MMM y"], M: ["MMM – ", "MMM y"]},
       yMMMEd: %{
         d: ["E, MMM d – ", "E, MMM d, y"],
         y: ["E, MMM d, y – ", "E, MMM d, y"],
         M: ["E, MMM d – ", "E, MMM d, y"]
       },
       yMMMM: %{y: ["MMMM y – ", "MMMM y"], M: ["MMMM – ", "MMMM y"]},
       yMMMd: %{
         d: ["MMM d – ", "d, y"],
         y: ["MMM d, y – ", "MMM d, y"],
         M: ["MMM d – ", "MMM d, y"]
       },
       yMd: %{
         d: ["M/d/y – ", "M/d/y"],
         y: ["M/d/y – ", "M/d/y"],
         M: ["M/d/y – ", "M/d/y"]
       },
       GyM: %{
         y: ["M/y – ", "M/y G"],
         M: ["M/y – ", "M/y G"],
         G: ["M/y G – ", "M/y G"]
       },
       GyMEd: %{
         d: ["E, M/d/y – ", "E, M/d/y G"],
         y: ["E, M/d/y – ", "E, M/d/y G"],
         M: ["E, M/d/y – ", "E, M/d/y G"],
         G: ["E, M/d/y G – ", "E, M/d/y G"]
       },
       Hv: %{H: ["HH – ", "HH v"]},
       hv: %{a: ["h a – ", "h a v"], h: ["h – ", "h a v"]}
     }}

# `date_time_relative_formats`

```elixir
@spec date_time_relative_formats(Cldr.Locale.locale_reference(), calendar()) ::
  {:ok, map()} | {:error, {module(), String.t()}}
```

Returns a map of the standard relative datetime formats for a given
locale and calendar.

## Arguments

* `locale` is any locale returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

* `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
  The default is `:gregorian`,

## Examples:

    iex> MicaWeb.Cldr.DateTime.Format.date_time_relative_formats(:en)
    {:ok, %Cldr.DateTime.Formats{
      full: "{1} 'at' {0}",
      long: "{1} 'at' {0}",
      medium: "{1}, {0}",
      short: "{1}, {0}"}
    }

    iex> MicaWeb.Cldr.DateTime.Format.date_time_relative_formats(:en, :buddhist)
    {:ok, %Cldr.DateTime.Formats{
      full: "{1} 'at' {0}",
      long: "{1} 'at' {0}",
      medium: "{1}, {0}",
      short: "{1}, {0}"}
    }

# `day_period_for`

```elixir
@spec day_period_for(
  Calendar.time(),
  Cldr.LanguageTag.t() | String.t() | Cldr.Locale.locale_name()
) ::
  atom() | {:error, {module(), String.t()}}
```

Returns the time period for a given time of day.

## Arguments

* `time` is any `Time.t` or a map with at least `:hour`,
  `:minute` and `:second` keys

* `language` is a binary representation of a valid and
  configured language in `Cldr`

The time period is a locale-specific key that is used
to localise a time into a textual representation of "am",
"pm", "noon", "midnight", "evening", "morning" and so on
as defined in the CLDR day period rules.

## Examples

    iex> MicaWeb.Cldr.DateTime.Format.day_period_for(~T[06:05:54.515228], :en)
    :morning1

    iex> MicaWeb.Cldr.DateTime.Format.day_period_for(~T[13:05:54.515228], :en)
    :afternoon1

    iex> MicaWeb.Cldr.DateTime.Format.day_period_for(~T[21:05:54.515228], :en)
    :night1

    iex> MicaWeb.Cldr.DateTime.Format.day_period_for(~T[21:05:54.515228], :fr)
    :evening1

# `gmt_format`

```elixir
@spec gmt_format(Cldr.Locale.locale_reference()) ::
  {:ok, [non_neg_integer() | String.t(), ...]}
  | {:error, {module(), String.t()}}
```

Returns the GMT offset format list for a
for a timezone offset for a given locale.

## Arguments

* `locale` is any locale returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

## Example

    iex> MicaWeb.Cldr.DateTime.Format.gmt_format(:en)
    {:ok, ["GMT", 0]}

# `gmt_unknown_format`

```elixir
@spec gmt_unknown_format(Cldr.Locale.locale_reference()) ::
  {:ok, String.t()} | {:error, {module(), String.t()}}
```

Returns the format string for a for an unknown GMT offset.

## Arguments

* `locale` is any locale returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

## Example

    iex> MicaWeb.Cldr.DateTime.Format.gmt_unknown_format(:en)
    {:ok, "GMT+?"}

    iex> MicaWeb.Cldr.DateTime.Format.gmt_unknown_format(:fr)
    {:ok, "GMT+?"}

# `gmt_zero_format`

```elixir
@spec gmt_zero_format(Cldr.Locale.locale_reference()) ::
  {:ok, String.t()} | {:error, {module(), String.t()}}
```

Returns the GMT format string for a
for a timezone with an offset of zero for
a given locale.

## Arguments

* `locale` is any locale returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

## Example

    iex> MicaWeb.Cldr.DateTime.Format.gmt_zero_format(:en)
    {:ok, "GMT"}

    iex> MicaWeb.Cldr.DateTime.Format.gmt_zero_format(:fr)
    {:ok, "UTC"}

# `hour_format`

```elixir
@spec hour_format(Cldr.Locale.locale_reference()) ::
  {:ok, {String.t(), String.t()}} | {:error, {module(), String.t()}}
```

Returns the positive and negative hour format
for a timezone offset for a given locale.

## Arguments

* `locale` is any locale returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

## Example

    iex> MicaWeb.Cldr.DateTime.Format.hour_format("en")
    {:ok, {"+HH:mm", "-HH:mm"}}

# `language_has_noon_and_midnight?`

```elixir
@spec language_has_noon_and_midnight?(
  Cldr.LanguageTag.t()
  | String.t()
  | Cldr.Locale.locale_name()
) ::
  boolean() | {:error, {module(), String.t()}}
```

Returns a boolean indicating is a given language defines the
notion of "noon" and "midnight"

## Arguments

* `language` is a binary representation of a valid and
  configured language in `Cldr`

## Examples

    iex> MicaWeb.Cldr.DateTime.Format.language_has_noon_and_midnight? :fr
    true

    iex> MicaWeb.Cldr.DateTime.Format.language_has_noon_and_midnight? :en
    true

    iex> MicaWeb.Cldr.DateTime.Format.language_has_noon_and_midnight? :af
    false

# `meta_zones`
*since 2.33.0* 

```elixir
@spec meta_zones(Cldr.Locale.locale_reference()) ::
  {:ok, map()} | {:error, {module(), String.t()}}
```

Returns the metazone data for a locale.

### Arguments

* `locale` is any locale returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

### Returns

* a map of localized metazone display data.

# `territories`

```elixir
@spec territories(Cldr.Locale.locale_reference()) ::
  {:ok, map()} | {:error, {module(), String.t()}}
```

Returns the localized territory names.

## Arguments

* `locale` is any locale returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

## Example

    iex> {:ok, territories} = MicaWeb.Cldr.DateTime.Format.territories(:en)
    iex> Map.get(territories, :AU)
    %{standard: "Australia"}

    iex> {:ok, territories} = MicaWeb.Cldr.DateTime.Format.territories(:en)
    iex> Map.get(territories, :NZ)
    %{standard: "New Zealand", variant: "Aotearoa New Zealand"}

    iex> {:ok, territories} = MicaWeb.Cldr.DateTime.Format.territories(:en)
    iex> Map.get(territories, :US)
    %{short: "US", standard: "United States"}

# `time_available_formats`

```elixir
@spec time_available_formats(Cldr.Locale.locale_reference(), calendar()) ::
  {:ok, formats()} | {:error, {module(), String.t()}}
```

Returns a map of the available time formats for a
given locale and calendar.

## Arguments

* `locale` is any locale returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

* `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
  The default is `:gregorian`.

## Examples:

    iex> MicaWeb.Cldr.DateTime.Format.time_available_formats :en

# `time_formats`

```elixir
@spec time_formats(Cldr.Locale.locale_reference(), calendar()) ::
  {:ok, map()} | {:error, {module(), String.t()}}
```

Returns a map of the standard time formats for a given locale and calendar.

The value of each format type is itself a key into the map returned by
`MicaWeb.Cldr.DateTime.Format.date_time_available_formats/2` which returns the
actual format string (or map of format strings by variant).

## Arguments

* `locale` is any locale returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

* `calendar` is any calendar returned by `Cldr.DateTime.Format.calendars_for/1`
  The default is `:gregorian`.

## Examples:

    iex> MicaWeb.Cldr.DateTime.Format.time_formats(:en)
    {:ok,
     %Cldr.Time.Formats{
       short: :ahmm,
       medium: :ahmmss,
       long: :ahmmssz,
       full: :ahmmsszzzz
     }}

    iex> MicaWeb.Cldr.DateTime.Format.time_formats(:en, :buddhist)
    {:ok,
     %Cldr.Time.Formats{
       short: :ahmm,
       medium: :ahmmss,
       long: :ahmmssz,
       full: :ahmmsszzzz
     }}

# `time_zones`
*since 2.33.0* 

```elixir
@spec time_zones(Cldr.Locale.locale_reference()) ::
  {:ok, map()} | {:error, {module(), String.t()}}
```

Returns the timezone data for a locale.

### Arguments

* `locale` is any locale returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

### Returns

* a map of localized timezone display data.

# `zone_fallback_format`

```elixir
@spec zone_fallback_format(Cldr.Locale.locale_reference()) ::
  {:ok, list()} | {:error, {module(), String.t()}}
```

Returns the time zone fallback format map for
a given locale.

## Arguments

* `locale` is any locale returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

## Example

    iex> MicaWeb.Cldr.DateTime.Format.zone_fallback_format(:en)
    {:ok, [1, " (", 0, ")"]}

# `zone_region_format`

```elixir
@spec zone_region_format(Cldr.Locale.locale_reference()) ::
  {:ok, map()} | {:error, {module(), String.t()}}
```

Returns the time zone region format map for
a given locale.

## Arguments

* `locale` is any locale returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0`. The default is `Cldr.get_locale/0`.

## Example

    iex> MicaWeb.Cldr.DateTime.Format.zone_region_format(:en)
    {:ok,
      %{
        standard: [0, " Standard Time"],
        generic: [0, " Time"],
        daylight: [0, " Daylight Time"]
      }
    }

---

*Consult [api-reference.md](api-reference.md) for complete listing*
