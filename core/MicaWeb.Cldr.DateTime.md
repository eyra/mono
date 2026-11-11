# `MicaWeb.Cldr.DateTime`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/cldr.ex#L1)

# `to_string`

```elixir
@spec to_string(Cldr.Calendar.any_date_time(), Keyword.t()) ::
  {:ok, String.t()} | {:error, {module(), String.t()}}
```

Formats a DateTime according to a format string
as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)

## Arguments

* `date_time` is a `t:DateTime.t/0` `or t:NaiveDateTime.t/0`struct or any map that contains
  one or more of the keys `:year`, `:month`, `:day`, `:hour`, `:minute` and `:second` or
  `:microsecond` with optional `:time_zone`, `:zone_abbr`, `:utc_offset`, `:std_offset`
  and `:calendar` fields.

* `options` is a keyword list of options for formatting.

## Options

* `:format` is one of `:short`, `:medium`, `:long`, `:full` or a format skeleton or
  any of the keys in the map returned by `Cldr.DateTime.Format.date_time_formats/3`.
  The default is `:medium`.

* `:date_format` is any one of `:short`, `:medium`, `:long`, `:full`. If defined,
  this option is used to format the date part of the date time. This option is
  only acceptable if the `:format` option is not specified, or is specified as either
  `:short`, `:medium`, `:long`, `:full`. If `:date_format` is not specified
  then the date format is defined by the `:format` option.

* `:time_format` is any one of `:short`, `:medium`, `:long`, `:full`. If defined,
  this option is used to format the time part of the date time. This option is
  only acceptable if the `:format` option is not specified, or is specified as either
  `:short`, `:medium`, `:long`, `:full`. If `:time_format` is not specified
  then the time format is defined by the `:format` option.

* `:style` is either `:at` or `:default`. When set to `:at` the date_time may
  be formatted with a localised string representing `<date> at <time>` if such
  a format exists. See `Cldr.DateTime.Format.date_time_at_formats/2`.

* `:prefer` is either `:unicode` (the default) or `:ascii`. A small number of
  formats have two variants - one using Unicode spaces (typically non-breaking space) and
  another using only ASCII whitespace. The `:ascii` format is primarily to support legacy
  use cases and is not recommended. See `Cldr.DateTime.available_formats/3`
  to see which formats have these variants.

* `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Cldr.get_locale/0`.

* `:number_system` a number system into which the formatted date_time digits should
  be transliterated.

* `:era` which, if set to `:variant`, will use a variant for the era if one
  is available in the requested locale. In the `:en` locale, for example, `era: :variant`
  will return `CE` instead of `AD` and `BCE` instead of `BC`.

* `:period` which, if set to `:variant`, will use a variant for the time period and
  flexible time period if one is available in the locale.  For example, in the `:en`
  locale `period: :variant` will return "pm" instead of "PM".

## Returns

* `{:ok, formatted_date_time}` or

* `{:error, reason}`

## Examples

    iex> {:ok, date_time} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
    iex> MicaWeb.Cldr.DateTime.to_string(date_time)
    {:ok, "Jan 1, 2000, 11:59:59 PM"}
    iex> MicaWeb.Cldr.DateTime.to_string(date_time, locale: "en")
    {:ok, "Jan 1, 2000, 11:59:59 PM"}
    iex> MicaWeb.Cldr.DateTime.to_string(date_time, format: :long, locale: "en")
    {:ok, "January 1, 2000, 11:59:59 PM UTC"}
    iex> MicaWeb.Cldr.DateTime.to_string(date_time, format: :hms, locale: "en")
    {:ok, "11:59:59 PM"}
    iex> MicaWeb.Cldr.DateTime.to_string(date_time, format: :full, locale: "en")
    {:ok, "Saturday, January 1, 2000, 11:59:59 PM Coordinated Universal Time"}
    iex> MicaWeb.Cldr.DateTime.to_string(date_time, format: :full, locale: "fr")
    {:ok, "samedi 1 janvier 2000, 23:59:59 temps universel coordonné"}

# `to_string!`

```elixir
@spec to_string!(Cldr.Calendar.any_date_time(), Keyword.t()) ::
  String.t() | no_return()
```

Formats a DateTime according to a format string
as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)
returning a formatted string or raising on error.

## Arguments

* `date_time` is a `t:DateTime.t/0` `or t:NaiveDateTime.t/0`struct or any map that contains
  one or more of the keys `:year`, `:month`, `:day`, `:hour`, `:minute` and `:second` or
  `:microsecond` with optional `:time_zone`, `:zone_abbr`, `:utc_offset`, `:std_offset`
  and `:calendar` fields.

* `options` is a keyword list of options for formatting.

## Options

* `:format` is one of `:short`, `:medium`, `:long`, `:full` or a format string or
  any of the keys in the map returned by `Cldr.DateTime.Format.date_time_formats/3`.
  The default is `:medium`. See [here](https://hexdocs.pm/ex_cldr_dates_times/readme.html#date-time-and-datetime-localization-formats)
  for more information about specifying formats.

* `:date_format` is any one of `:short`, `:medium`, `:long`, `:full`. If defined,
  this option is used to format the date part of the date time. This option is
  only acceptable if the `:format` option is not specified, or is specified as either
  `:short`, `:medium`, `:long`, `:full`. If `:date_format` is not specified
  then the date format is defined by the `:format` option.

* `:time_format` is any one of `:short`, `:medium`, `:long`, `:full`. If defined,
  this option is used to format the time part of the date time. This option is
  only acceptable if the `:format` option is not specified, or is specified as either
  `:short`, `:medium`, `:long`, `:full`. If `:time_format` is not specified
  then the time format is defined by the `:format` option.

* `:style` is either `:at` or `:default`. When set to `:at` the date_time may
  be formatted with a localised string representing `<date> at <time>` if such
  a format exists. See `Cldr.DateTime.Format.date_time_at_formats/2`.

* `:prefer` is either `:unicode` (the default) or `:ascii`. A small number of
  formats have two variants - one using Unicode spaces (typically non-breaking space) and
  another using only ASCII whitespace. The `:ascii` format is primarily to support legacy
  use cases and is not recommended. See `Cldr.DateTime.available_formats/3`
  to see which formats have these variants.

* `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Cldr.get_locale/0`.

* `:number_system` a number system into which the formatted date_time digits should
  be transliterated.

* `:era` which, if set to `:variant`, will use a variant for the era if one
  is available in the requested locale. In the `:en` locale, for example, `era: :variant`
  will return `CE` instead of `AD` and `BCE` instead of `BC`.

* `period: :variant` will use a variant for the time period and flexible time period if
  one is available in the locale.  For example, in the `:en` locale `period: :variant` will
  return "pm" instead of "PM".

## Returns

* `formatted_date_time` or

* raises an exception.

## Examples

    iex> {:ok, date_time} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
    iex> MicaWeb.Cldr.DateTime.to_string!(date_time, locale: :en)
    "Jan 1, 2000, 11:59:59 PM"
    iex> MicaWeb.Cldr.DateTime.to_string!(date_time, format: :long, locale: :en)
    "January 1, 2000, 11:59:59 PM UTC"
    iex> MicaWeb.Cldr.DateTime.to_string!(date_time, format: :full, locale: :en)
    "Saturday, January 1, 2000, 11:59:59 PM Coordinated Universal Time"
    iex> MicaWeb.Cldr.DateTime.to_string!(date_time, format: :full, locale: :fr)
    "samedi 1 janvier 2000, 23:59:59 temps universel coordonné"

---

*Consult [api-reference.md](api-reference.md) for complete listing*
