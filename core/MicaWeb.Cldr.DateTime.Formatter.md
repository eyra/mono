# `MicaWeb.Cldr.DateTime.Formatter`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/cldr.ex#L1)

Implements the compilation and execution of
date, time and datetime formats.

# `format`

```elixir
@spec format(
  Cldr.Calendar.any_date_time(),
  String.t(),
  Cldr.Locale.locale_reference(),
  Keyword.t()
) ::
  {:ok, String.t()} | {:error, {module(), String.t()}}
```

Returns the formatted and localised date, time or datetime
for a given `Date`, `Time`, `DateTime` or struct with the
appropriate fields.

## Arguments

* `date` is a `Date`, `Time`, `DateTime` or other struct that
contains the required date and time fields.

* `format` is a valid format string, for example `yy/MM/dd hh:MM`

* `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0` struct. The default is `Cldr.get_locale/0`

* `options` is a keyword list of options.

## Options

* `:number_system`.  The resulting formatted and localised date/time
string will be transliterated into this number system. Number system
is anything returned from `MicaWeb.Cldr.Number.System.number_systems_for/1`

*NOTE* This function is called by `Cldr.Date.to_string/2`, `Cldr.Time.to_string/2`
and `Cldr.DateTime.to_string/2` which is the preferred API.

## Examples

    iex> MicaWeb.Cldr.DateTime.Formatter.format(~U[2017-09-03 10:23:00.0Z], "yy/MM/dd hh:MM", "en")
    {:ok, "17/09/03 10:09"}

# `gmt_tz_format`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
