# `MicaWeb.Cldr.Date`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/cldr.ex#L1)

# `to_string`

```elixir
@spec to_string(Cldr.Calendar.any_date_time(), Keyword.t()) ::
  {:ok, String.t()} | {:error, {module(), String.t()}}
```

Formats a date according to a format string
as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html).

## Arguments

* `date` is a `t:Date.t/0` struct or any map that contains one or more
  of the keys `:year`, `:month`, `:day` and optionally `:calendar`.

* `options` is a keyword list of options for formatting.

## Options

* `:format` is one of `:short`, `:medium`, `:long`, `:full`, or a format id
  or a format string. The default is `:medium` for full dates (that is,
  dates having `:year`, `:month`, `:day` and `:calendar` fields). The
  default for partial dates is to derive a candidate format id from the date and
  find the best match from the formats returned by
  `Cldr.Date.available_formats/3`. See [here](https://hexdocs.pm/ex_cldr_dates_times/readme.html#date-time-and-datetime-localization-formats)
  for more information about specifying formats.

* `:locale` any locale returned by `Cldr.known_locale_names/1`.
  The default is `Cldr.get_locale/0`.

* `:number_system` a number system into which the formatted date digits
  should be transliterated.

* `:prefer` is either `:unicode` (the default) or `:ascii`. A small number of
  formats have two variants - one using Unicode spaces (typically non-breaking space) and
  another using only ASCII whitespace. The `:ascii` format is primarily to support legacy
  use cases and is not recommended. See `Cldr.Date.available_formats/3`
  to see which formats have these variants. Currently no date-specific
  formats have such variants but they may in the future.

* `:era` which, if set to `:variant`, will use a variant for the era if one
  is available in the requested locale. In the `:en` locale, for example, `era: :variant`
  will return `CE` instead of `AD` and `BCE` instead of `BC`.

## Returns

* `{:ok, formatted_string}` or

* `{:error, reason}`

## Examples

    # Full dates have the default format `:medium`
    iex> MicaWeb.Cldr.Date.to_string(~D[2017-07-10], locale: :en)
    {:ok, "Jul 10, 2017"}

    iex> MicaWeb.Cldr.Date.to_string(~D[2017-07-10], format: :medium, locale: :en)
    {:ok, "Jul 10, 2017"}

    iex> MicaWeb.Cldr.Date.to_string(~D[2017-07-10], format: :full, locale: :en)
    {:ok, "Monday, July 10, 2017"}

    iex> MicaWeb.Cldr.Date.to_string(~D[2017-07-10], format: :short, locale: :en)
    {:ok, "7/10/17"}

    iex> MicaWeb.Cldr.Date.to_string(~D[2017-07-10], format: :short, locale: "fr")
    {:ok, "10/07/2017"}

    # A partial date with a derived "best match" format
    iex> MicaWeb.Cldr.Date.to_string(%{year: 2024, month: 6}, locale: "fr")
    {:ok, "6/2024"}

    # A partial date with a best match CLDR-defined format
    iex> MicaWeb.Cldr.Date.to_string(%{year: 2024, month: 6}, format: :yMMM, locale: "fr")
    {:ok, "juin 2024"}

    # Sometimes the available date fields can't be mapped to an available
    # CLDR defined format.
    iex> MicaWeb.Cldr.Date.to_string(%{year: 2024, day: 3}, locale: "fr")
    {:error,
     {Cldr.DateTime.UnresolvedFormat, "No available format resolved for :dy"}}

# `to_string!`

```elixir
@spec to_string!(Cldr.Calendar.any_date_time(), Keyword.t()) ::
  String.t() | no_return()
```

Formats a date according to a format string
as defined in CLDR and described in [TR35](http://unicode.org/reports/tr35/tr35-dates.html)
or raises an exception.

## Arguments

* `date` is a `t:Date.t/0` struct or any map that contains one or more
  of the keys `:year`, `:month`, `:day` and optionally `:calendar`.

* `options` is a keyword list of options for formatting.

## Options

* `:format` is one of `:short`, `:medium`, `:long`, `:full`, or a format id
  or a format string. The default is `:medium` for full dates (that is,
  dates having `:year`, `:month`, `:day` and `:calendar` fields). The
  default for partial dates is to derive a candidate format id from the date and
  find the best match from the formats returned by
  `Cldr.Date.available_formats/3`. See [here](https://hexdocs.pm/ex_cldr_dates_times/readme.html#date-time-and-datetime-localization-formats)
  for more information about specifying formats.

* `:locale` any locale returned by `Cldr.known_locale_names/1`.
  The default is `Cldr.get_locale/0`.

* `:number_system` a number system into which the formatted date digits
  should be transliterated.

* `:prefer` is either `:unicode` (the default) or `:ascii`. A small number of
  formats have two variants - one using Unicode spaces (typically non-breaking space) and
  another using only ASCII whitespace. The `:ascii` format is primarily to support legacy
  use cases and is not recommended. See `Cldr.Date.available_formats/3`
  to see which formats have these variants. Currently no date-specific
  formats have such variants but they may in the future.

* `:era` which, if set to `:variant`, will use a variant for the era if one
  is available in the requested locale. In the `:en` locale, for example, `era: :variant`
  will return `CE` instead of `AD` and `BCE` instead of `BC`.

## Returns

* `formatted_date` or

* raises an exception.

## Examples

    iex> MicaWeb.Cldr.Date.to_string!(~D[2017-07-10], locale: :en)
    "Jul 10, 2017"

    iex> MicaWeb.Cldr.Date.to_string!(~D[2017-07-10], format: :medium, locale: :en)
    "Jul 10, 2017"

    iex> MicaWeb.Cldr.Date.to_string!(~D[2017-07-10], format: :full, locale: :en)
    "Monday, July 10, 2017"

    iex> MicaWeb.Cldr.Date.to_string!(~D[2017-07-10], format: :short, locale: :en)
    "7/10/17"

    iex> MicaWeb.Cldr.Date.to_string!(~D[2017-07-10], format: :short, locale: "fr")
    "10/07/2017"

    # A partial date with a derived "best match" format
    iex> MicaWeb.Cldr.Date.to_string!(%{year: 2024, month: 6}, locale: "fr")
    "6/2024"

    # A partial date with a best match CLDR-defined format
    iex> MicaWeb.Cldr.Date.to_string!(%{year: 2024, month: 6}, format: :yMMM, locale: "fr")
    "juin 2024"

---

*Consult [api-reference.md](api-reference.md) for complete listing*
