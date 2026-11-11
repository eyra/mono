# `MicaWeb.Cldr.Date.Interval`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/cldr.ex#L1)

Interval formats allow for software to format intervals like "Jan 10-12, 2008" as a
shorter and more natural format than "Jan 10, 2008 - Jan 12, 2008". They are designed
to take a start and end date, time or datetime plus a formatting pattern
and use that information to produce a localized format.

See `MicaWeb.Cldr.Date.Interval.to_string/3` and `MicaWeb.Cldr.Interval.to_string/3`

# `do_to_string!`

# `to_string`

```elixir
@spec to_string(Calendar.date() | nil, Calendar.date() | nil, Keyword.t()) ::
  {:ok, String.t()} | {:error, {module(), String.t()}}
```

Returns a interval formed from two dates as
a localised string.

## Arguments

* `from` is any map that conforms to the
  `Calendar.date` type.

* `to` is any map that conforms to the
  `Calendar.date` type. `to` must occur
  on or after `from`.

* `options` is a keyword list of options. The default is
  `[format: :medium, style: :date]`.

Either `from` or `to` may also be `nil`, in which case an
open interval is formatted and the non-nil item is formatted
as a standalone date.

## Options

* `:format` is one of `:short`, `:medium` or `:long` or a
  specific format type or a string representing of an interval
  format. The default is `:medium`.

* `:style` supports different formatting styles. The
  alternatives are `:date`, `:month_and_day`, `:month`
  and `:year_and_month`. The default is `:date`.

* `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Elixir.MicaWeb.Cldr.get_locale/0`

* `number_system:` a number system into which the formatted date digits should
  be transliterated

## Returns

* `{:ok, string}` or

* `{:error, {exception, reason}}`

## Notes

* For more information on interval format string
  see the `Cldr.Interval`.

* The available predefined formats that can be applied are the
  keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
  where `"en"` can be replaced by any configuration locale name and `:gregorian`
  is the underlying CLDR calendar type.

* In the case where `from` and `to` are equal, a single
  date is formatted instead of an interval

## Examples

    iex> MicaWeb.Cldr.Date.Interval.to_string ~D[2020-01-01], ~D[2020-12-31]
    {:ok, "Jan 1 – Dec 31, 2020"}

    iex> MicaWeb.Cldr.Date.Interval.to_string ~D[2020-01-01], ~D[2020-01-12]
    {:ok, "Jan 1 – 12, 2020"}

    iex> MicaWeb.Cldr.Date.Interval.to_string ~D[2020-01-01], ~D[2020-01-12],
    ...> format: :long
    {:ok, "Wed, Jan 1 – Sun, Jan 12, 2020"}

    iex> MicaWeb.Cldr.Date.Interval.to_string ~D[2020-01-01], ~D[2020-12-01],
    ...> format: :long, style: :year_and_month
    {:ok, "January – December 2020"}

    iex> MicaWeb.Cldr.Date.Interval.to_string ~D[2020-01-01], ~D[2020-01-12],
    ...> format: :short
    {:ok, "1/1/2020 – 1/12/2020"}

    iex> MicaWeb.Cldr.Date.Interval.to_string ~D[2020-01-01], ~D[2020-01-12],
    ...> format: :long, locale: "fr"
    {:ok, "mer. 1 – dim. 12 janv. 2020"}

    iex> MicaWeb.Cldr.Date.Interval.to_string ~D[2020-01-01], ~D[2020-01-12],
    ...> format: :long, locale: "th", number_system: :thai
    {:ok, "พุธ ๑ ม.ค. – อาทิตย์ ๑๒ ม.ค. ๒๐๒๐"}

# `to_string!`

```elixir
@spec to_string!(Calendar.date() | nil, Calendar.date() | nil, Keyword.t()) ::
  String.t() | no_return()
```

Returns a interval formed from two dates as
a localised string.

## Arguments

* `from` is any map that conforms to the
  `Calendar.date` type.

* `to` is any map that conforms to the
  `Calendar.date` type. `to` must occur
  on or after `from`.

* `options` is a keyword list of options. The default is
  `[format: :medium, style: :date]`.

Either `from` or `to` may also be `nil`, in which case an
open interval is formatted and the non-nil item is formatted
as a standalone date.

## Options

* `:format` is one of `:short`, `:medium` or `:long` or a
  specific format type or a string representing of an interval
  format. The default is `:medium`.

* `:style` supports different formatting styles. The
  alternatives are `:date`, `:month_and_day`, `:month`
  and `:year_and_month`. The default is `:date`.

* `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Elixir.MicaWeb.Cldr.get_locale/0`.

* `number_system:` a number system into which the formatted date digits should
  be transliterated.

## Returns

* `string` or

* raises an exception

## Notes

* For more information on interval format string
  see the `Cldr.Interval`.

* The available predefined formats that can be applied are the
  keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
  where `"en"` can be replaced by any configuration locale name and `:gregorian`
  is the underlying CLDR calendar type.

* In the case where `from` and `to` are equal, a single
  date is formatted instead of an interval

## Examples

    iex> MicaWeb.Cldr.Date.Interval.to_string! Date.range(~D[2020-01-01], ~D[2020-12-31])
    "Jan 1 – Dec 31, 2020"

    iex> MicaWeb.Cldr.Date.Interval.to_string! Date.range(~D[2020-01-01], ~D[2020-01-12])
    "Jan 1 – 12, 2020"

    iex> MicaWeb.Cldr.Date.Interval.to_string! Date.range(~D[2020-01-01], ~D[2020-01-12]),
    ...> format: :long
    "Wed, Jan 1 – Sun, Jan 12, 2020"

    iex> MicaWeb.Cldr.Date.Interval.to_string! Date.range(~D[2020-01-01], ~D[2020-12-01]),
    ...> format: :long, style: :year_and_month
    "January – December 2020"

    iex> use CalendarInterval
    iex> MicaWeb.Cldr.Date.Interval.to_string! ~I"2020-01/12"
    "Jan 1 – Dec 31, 2020"

    iex> MicaWeb.Cldr.Date.Interval.to_string! Date.range(~D[2020-01-01], ~D[2020-01-12]),
    ...> format: :short
    "1/1/2020 – 1/12/2020"

    iex> MicaWeb.Cldr.Date.Interval.to_string! Date.range(~D[2020-01-01], ~D[2020-01-12]),
    ...> format: :long, locale: "fr"
    "mer. 1 – dim. 12 janv. 2020"

---

*Consult [api-reference.md](api-reference.md) for complete listing*
