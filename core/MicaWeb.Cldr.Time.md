# `MicaWeb.Cldr.Time`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/cldr.ex#L1)

# `to_string`

```elixir
@spec to_string(Cldr.Calendar.any_date_time(), Keyword.t()) ::
  {:ok, String.t()} | {:error, {module(), String.t()}}
```

Formats a time according to a format string
as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)

## Returns

* `{:ok, formatted_time}` or

* `{:error, reason}`.

## Arguments

* `time` is a `t:Time.t/0` struct or any map that contains
  one or more of the keys `:hour`, `:minute`, `:second` and optionally `:microsecond`,
  `:time_zone`, `:zone_abbr`, `:utc_offset` and `:std_offset`.

* `options` is a keyword list of options for formatting.

## Options

* `:format` is one of `:short`, `:medium`, `:long`, `:full`, or a format id
  or a format string. The default is `:medium` for full times (that is,
  times having `:hour`, `:minute` and `:second` fields). The
  default for partial times is to derive a candidate format from the time and
  find the best match from the formats returned by
  `Cldr.Time.available_formats/2`. See [here](https://hexdocs.pm/ex_cldr_dates_times/readme.html#date-time-and-datetime-localization-formats)
  for more information about specifying formats.

* `:locale` any locale returned by `Cldr.known_locale_names/1`.  The default is
  `Cldr.get_locale/0`.

* `:number_system` a number system into which the formatted date digits should
  be transliterated.

* `:prefer` is either `:unicode` (the default) or `:ascii`. A small number of
  formats have two variants - one using Unicode spaces (typically non-breaking space) and
  another using only ASCII whitespace. The `:ascii` format is primarily to support legacy
  use cases and is not recommended. See `Cldr.Time.available_formats/3`
  to see which formats have these variants.

* `period: :variant` will use a variant for the time period and flexible time period if
  one is available in the locale.  For example, in the `:en` locale `period: :variant` will
  return "pm" instead of "PM".

## Examples

    iex> MicaWeb.Cldr.Time.to_string(~T[07:35:13.215217])
    {:ok, "7:35:13 AM"}

    iex> MicaWeb.Cldr.Time.to_string(~T[07:35:13.215217], format: :short)
    {:ok, "7:35 AM"}

    iex> MicaWeb.Cldr.Time.to_string(~T[07:35:13.215217], format: :short, period: :variant)
    {:ok, "7:35 am"}

    iex> MicaWeb.Cldr.Time.to_string(~T[07:35:13.215217], format: :medium, locale: :fr)
    {:ok, "07:35:13"}

    iex> MicaWeb.Cldr.Time.to_string(~T[07:35:13.215217], format: :medium)
    {:ok, "7:35:13 AM"}

    iex> {:ok, date_time} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
    iex> MicaWeb.Cldr.Time.to_string(date_time, format: :long)
    {:ok, "11:59:59 PM UTC"}

    # A partial time with a best match CLDR-defined format
    iex> MicaWeb.Cldr.Time.to_string(%{hour: 23, minute: 11})
    {:ok, "11:11 PM"}

    # Sometimes the available time fields can't be mapped to an available
    # CLDR defined format.
    iex> MicaWeb.Cldr.Time.to_string(%{minute: 11})
    {:error,
     {Cldr.DateTime.UnresolvedFormat, "No available format resolved for :m"}}

# `to_string!`

```elixir
@spec to_string!(Cldr.Calendar.any_date_time(), Keyword.t()) ::
  String.t() | no_return()
```

Formats a time according to a format string
as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)
or raises an exception.

## Arguments

* `time` is a `t:Time.t/0` struct or any map that contains
  one or more of the keys `:hour`, `:minute`, `:second` and optionally `:microsecond`,
  `:time_zone`, `:zone_abbr`, `:utc_offset` and `:std_offset`.

* `options` is a keyword list of options for formatting.

## Options

* `:format` is one of `:short`, `:medium`, `:long`, `:full`, or a format id
  or a format string. The default is `:medium` for full times (that is,
  times having `:hour`, `:minute` and `:second` fields). The
  default for partial times is to derive a candidate format from the time and
  find the best match from the formats returned by
  `Cldr.Time.available_formats/2`. See [here](https://hexdocs.pm/ex_cldr_dates_times/readme.html#date-time-and-datetime-localization-formats)
  for more information about specifying formats.

* `:locale` any locale returned by `Cldr.known_locale_names/1`.  The default is
  `Cldr.get_locale/0`.

* `:number_system` a number system into which the formatted date digits should
  be transliterated.

* `:prefer` is either `:unicode` (the default) or `:ascii`. A small number of
  formats have two variants - one using Unicode spaces (typically non-breaking space) and
  another using only ASCII whitespace. The `:ascii` format is primarily to support legacy
  use cases and is not recommended. See `Cldr.Time.available_formats/3`
  to see which formats have these variants.

* `period: :variant` will use a variant for the time period and flexible time period if
  one is available in the locale.  For example, in the `:en` locale `period: :variant` will
  return "pm" instead of "PM".

## Returns

* `formatted_time_string` or

* raises an exception.

## Examples

    iex> MicaWeb.Cldr.Time.to_string!(~T[07:35:13.215217])
    "7:35:13 AM"

    iex> MicaWeb.Cldr.Time.to_string!(~T[07:35:13.215217], format: :short)
    "7:35 AM"

    iex> MicaWeb.Cldr.Time.to_string!(~T[07:35:13.215217], format: :short, period: :variant)
    "7:35 am"

    iex> MicaWeb.Cldr.Time.to_string!(~T[07:35:13.215217], format: :medium, locale: :fr)
    "07:35:13"

    iex> MicaWeb.Cldr.Time.to_string!(~T[07:35:13.215217], format: :medium)
    "7:35:13 AM"

    iex> {:ok, date_time} = DateTime.from_naive(~N[2000-01-01 23:59:59.0], "Etc/UTC")
    iex> MicaWeb.Cldr.Time.to_string! date_time, format: :long
    "11:59:59 PM UTC"

    # A partial time with a best match CLDR-defined format
    iex> MicaWeb.Cldr.Time.to_string!(%{hour: 23, minute: 11})
    "11:11 PM"

---

*Consult [api-reference.md](api-reference.md) for complete listing*
