# `MicaWeb.Cldr.DateTime.Interval`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/cldr.ex#L1)

Interval formats allow for software to format intervals like "Jan 10-12, 2008" as a
shorter and more natural format than "Jan 10, 2008 - Jan 12, 2008". They are designed
to take a start and end date, time or datetime plus a formatting pattern
and use that information to produce a localized format.

See `Cldr.Interval.to_string/3` and `Cldr.DateTime.Interval.to_string/3`

# `do_to_string`

# `do_to_string!`

# `to_string`

```elixir
@spec to_string(
  Calendar.naive_datetime() | nil,
  Calendar.naive_datetime() | nil,
  Keyword.t()
) ::
  {:ok, String.t()} | {:error, {module(), String.t()}}
```

Returns a string representing the formatted
interval formed by two dates.

## Arguments

* `from` is any map that conforms to the
  `Calendar.datetime` type.

* `to` is any map that conforms to the
  `Calendar.datetime` type. `to` must occur
  on or after `from`.

* `options` is a keyword list of options. The default is
  `[format: :medium]`.

Either `from` or `to` may also be `nil`, in which case an
open interval is formatted and the non-nil item is formatted
as a standalone datetime.

## Options

* `:format` is one of `:short`, `:medium` or `:long` or a
  specific format type or a string representing of an interval
  format. The default is `:medium`.

* `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Elixir.MicaWeb.Cldr.get_locale/0`

* `number_system:` a number system into which the formatted date digits should
  be transliterated

## Returns

* `{:ok, string}` or

* `{:error, {exception, reason}}`

## Notes

* `CalendarInterval` support requires adding the
  dependency [calendar_interval](https://hex.pm/packages/calendar_interval)
  to the `deps` configuration in `mix.exs`.

* For more information on interval format string
  see the `Cldr.Interval`.

* The available predefined formats that can be applied are the
  keys of the map returned by `Cldr.DateTime.Format.interval_formats("en", :gregorian)`
  where `"en"` can be replaced by any configuration locale name and `:gregorian`
  is the underlying CLDR calendar type.

* In the case where `from` and `to` are equal, a single
  date is formatted instead of an interval

## Examples

    iex> MicaWeb.Cldr.DateTime.Interval.to_string ~U[2020-01-01 00:00:00.0Z],
    ...> ~U[2020-12-31 10:00:00.0Z]
    {:ok, "Jan 1, 2020, 12:00:00 AM – Dec 31, 2020, 10:00:00 AM"}

    iex> MicaWeb.Cldr.DateTime.Interval.to_string ~U[2020-01-01 00:00:00.0Z], nil
    {:ok, "Jan 1, 2020, 12:00:00 AM –"}

# `to_string!`

```elixir
@spec to_string!(
  Calendar.naive_datetime() | nil,
  Calendar.naive_datetime() | nil,
  Keyword.t()
) ::
  String.t() | no_return()
```

Returns a string representing the formatted
interval formed by two dates or raises an
exception.

## Arguments

* `from` is any map that conforms to the
  `Calendar.datetime` type.

* `to` is any map that conforms to the
  `Calendar.datetime` type. `to` must occur
  on or after `from`.

* `options` is a keyword list of options. The default is
  `[format: :medium]`.

Either `from` or `to` may also be `nil`, in which case an
open interval is formatted and the non-nil item is formatted
as a standalone datetime.

## Options

* `:format` is one of `:short`, `:medium` or `:long` or a
  specific format type or a string representing of an interval
  format. The default is `:medium`.

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
  date is formatted instead of an interval.

## Examples

    iex> MicaWeb.Cldr.DateTime.Interval.to_string! ~U[2020-01-01 00:00:00.0Z],
    ...> ~U[2020-12-31 10:00:00.0Z]
    "Jan 1, 2020, 12:00:00 AM – Dec 31, 2020, 10:00:00 AM"

---

*Consult [api-reference.md](api-reference.md) for complete listing*
