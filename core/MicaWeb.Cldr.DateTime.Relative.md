# `MicaWeb.Cldr.DateTime.Relative`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/cldr.ex#L1)

# `to_string`

```elixir
@spec to_string(number() | Date.t() | DateTime.t(), Keyword.t()) ::
  {:ok, String.t()} | {:error, {module(), String.t()}}
```

Returns a string representing a relative time (ago, in) for a given
number, date, time or datetime.

### Arguments

* `relative` is an integer or `t:Calendar.datetime/0`, `t:Calendar.date/0`, or
  `t:Calendar.time/0` representing the time distance from `now` or from
  `options[:relative_to]`.

* `options` is a `t:Keyword.t/0` list of options.

### Options

* `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Cldr.get_locale/0`.

* `:format` is the type of the formatted string.  Allowable values are `:standard`,
  `:narrow` or `:short`. The default is `:standard`.

* `:style` determines whether to return a standard relative string ("tomorrow") or
  an "at" string ("tomorrow at 3:00 PM"). The supported values are `:standard` (the default)
  or `:at`.  Note that `style: :at` is only applied when:

  * `:unit` is not a time unit (ie not `:hour`, `:minute` or `:second`)
  * *and* when `:relative` is a `t:Calendar.datetime/0` or
  * *or* the `:at` option is set to a `t:Calendar.time/0`

* `:unit` is the time unit for the formatting.  The allowable units are `:second`, `:minute`,
  `:hour`, `:day`, `:week`, `:month`, `:year`, `:mon`, `:tue`, `:wed`, `:thu`, `:fri`, `:sat`,
  `:sun`, `:quarter`. If no `:unit` is specified, one will be derived using the
  `:derive_unit_from` option.

* `:relative_to` is the baseline `date` or `datetime` from which the difference
  from `relative` is calculated when `relative` is a `t:Calendar.date/0` or a
  `t:Calendar.datetime/0`. The default for a `t:Calendar.date/0` is `Date.utc_today/0`;
  for a `t:Calendar.datetime/0` it is `DateTime.utc_now/0` and for a `t:Calendar.time/0` it
  is `Time.utc_now/0`.

* `:time` is any `t:Calendar.time/0` that is used when `style: :at` is being applied. The
  default is to use the time component of `relative`.

* `:time_format` is the format option to be passed to `Cldr.Time.to_string/3` if the `:style`
  option is `:at` and `relative` is a `t:Calendar.datetime/0` or the `:time` option is set.
  The default is `:short`.

* `:at_format` is one of `:short`, `:medium`, `:long` or `:full`. It is used to determine the
  format joining together the `relative` string and the `:time` string when `:style` is `:at`.
  The default is `:short` if `:format` is either `:short` or `:narrow`. Otherwise the
  default is `:medium`.

* `:derive_unit_from` is used to derive the most appropriate time unit if none is provided.
  There are two ways to specify `:derive_unit_from`.

  * The first option is a map. The map is required to have the keys `:second`, `:minute`, `:hour`,
    `:day`, `:week`, `:month`, and `:year` with the values being the number of seconds below
    which the key defines the time unit difference. This is the default and its value is:

    %{second: 1, month: 2629743.83, day: 86400, year: 31556926, minute: 60, hour: 3600, week: 604800}

  * The second option is to specify a function reference. The function must take four
    arguments as described below.

#### The :derive_unit_from *function*

* The function must take four arguments:
  * `relative`, being the first argument to `to_string/3`.
  * `relative_to` being the value of option `:relative_to` or its default value.
  * `time_difference` being the difference in seconds between `relative`
    and `relative_to`.
  * `unit` being the requested time unit which may be `nil`. If `nil` then
    the time unit must be derived and the `time_difference` scaled to that
    time unit. If specified then the `time_difference` must be scaled to
    the specified time unit.

* The function must return a tuple of the form `{relative, unit}` where
  `relative` is an integer value and `unit` is the appropriate time unit atom.

* See the `Cldr.DateTime.Relative.derive_unit_from/4` function for an example.

### Returns

* `{:ok, formatted_string}` or

* `{:error, {exception, reason}}`

### Examples

    iex> MicaWeb.Cldr.DateTime.Relative.to_string(-1)
    {:ok, "1 second ago"}

    iex> MicaWeb.Cldr.DateTime.Relative.to_string(1)
    {:ok, "in 1 second"}

    iex> MicaWeb.Cldr.DateTime.Relative.to_string(1, unit: :day)
    {:ok, "tomorrow"}

    iex> MicaWeb.Cldr.DateTime.Relative.to_string(1, unit: :day, locale: "fr")
    {:ok, "demain"}

    iex> MicaWeb.Cldr.DateTime.Relative.to_string(1, unit: :day, format: :narrow)
    {:ok, "tomorrow"}

    iex> MicaWeb.Cldr.DateTime.Relative.to_string(1234, unit: :year)
    {:ok, "in 1,234 years"}

    iex> MicaWeb.Cldr.DateTime.Relative.to_string(1234, unit: :year, locale: "fr")
    {:ok, "dans 1 234 ans"}

    iex> MicaWeb.Cldr.DateTime.Relative.to_string(31)
    {:ok, "in 31 seconds"}

    iex> MicaWeb.Cldr.DateTime.Relative.to_string(~D[2017-04-29], relative_to: ~D[2017-04-26])
    {:ok, "in 3 days"}

    iex> MicaWeb.Cldr.DateTime.Relative.to_string(310, format: :short, locale: "fr")
    {:ok, "dans 5 min"}

    iex> MicaWeb.Cldr.DateTime.Relative.to_string(310, format: :narrow, locale: "fr")
    {:ok, "+5 min"}

    iex> MicaWeb.Cldr.DateTime.Relative.to_string(2, unit: :wed, format: :short, locale: "en")
    {:ok, "in 2 Wed."}

    iex> MicaWeb.Cldr.DateTime.Relative.to_string(1, unit: :wed, format: :short)
    {:ok, "next Wed."}

    iex> MicaWeb.Cldr.DateTime.Relative.to_string(-1, unit: :wed, format: :short)
    {:ok, "last Wed."}

    iex> MicaWeb.Cldr.DateTime.Relative.to_string(-1, unit: :wed)
    {:ok, "last Wednesday"}

    iex> MicaWeb.Cldr.DateTime.Relative.to_string(-1, unit: :quarter)
    {:ok, "last quarter"}

    iex> MicaWeb.Cldr.DateTime.Relative.to_string(-1, unit: :mon, locale: "fr")
    {:ok, "lundi dernier"}

    iex> MicaWeb.Cldr.DateTime.Relative.to_string(~D[2017-04-29], unit: :ziggeraut)
    {:error, {Cldr.DateTime.UnknownTimeUnit,
     "Unknown time unit :ziggeraut.  Valid time units are [:day, :fri, :hour, :minute, :mon, :month, :quarter, :sat, :second, :sun, :thu, :tue, :wed, :week, :year]"}}

# `to_string!`

```elixir
@spec to_string!(number() | Date.t() | DateTime.t(), Keyword.t()) :: String.t()
```

Returns a string representing a relative time (ago, in) for a given
number, date, time or datetime.

### Arguments

* `relative` is an integer or `t:Calendar.datetime/0`, `t:Calendar.date/0`, or
  `t:Calendar.time/0` representing the time distance from `now` or from
  `options[:relative_to]`.

* `options` is a `t:Keyword.t/0` list of options.

### Options

* `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
  or a `t:Cldr.LanguageTag.t/0` struct.  The default is `Cldr.get_locale/0`.

* `:format` is the type of the formatted string.  Allowable values are `:standard`,
  `:narrow` or `:short`. The default is `:standard`.

* `:style` determines whether to return a standard relative string ("tomorrow") or
  an "at" string ("tomorrow at 3:00 PM"). The supported values are `:standard` (the default)
  or `:at`.  Note that `style: :at` is only applied when:

  * `:unit` is not a time unit (ie not `:hour`, `:minute` or `:second`)
  * *and* when `:relative` is a `t:Calendar.datetime/0` or
  * *or* the `:at` option is set to a `t:Calendar.time/0`

* `:unit` is the time unit for the formatting.  The allowable units are `:second`, `:minute`,
  `:hour`, `:day`, `:week`, `:month`, `:year`, `:mon`, `:tue`, `:wed`, `:thu`, `:fri`, `:sat`,
  `:sun`, `:quarter`. If no `:unit` is specified, one will be derived using the
  `:derive_unit_from` option.

* `:relative_to` is the baseline `date` or `datetime` from which the difference
  from `relative` is calculated when `relative` is a `t:Calendar.date/0` or a
  `t:Calendar.datetime/0`. The default for a `t:Calendar.date/0` is `Date.utc_today/0`;
  for a `t:Calendar.datetime/0` it is `DateTime.utc_now/0` and for a `t:Calendar.time/0` it
  is `Time.utc_now/0`.

* `:time` is any `t:Calendar.time/0` that is used when `style: :at` is being applied. The
  default is to use the time component of `relative`.

* `:time_format` is the format option to be passed to `Cldr.Time.to_string/3` if the `:style`
  option is `:at` and `relative` is a `t:Calendar.datetime/0` or the `:time` option is set.
  The default is `:short`.

* `:at_format` is one of `:short`, `:medium`, `:long` or `:full`. It is used to determine the
  format joining together the `relative` string and the `:time` string when `:style` is `:at`.
  The default is `:short` if `:format` is either `:short` or `:narrow`. Otherwise the
  default is `:medium`.

* `:derive_unit_from` is used to derive the most appropriate time unit if none is provided.
  There are two ways to specify `:derive_unit_from`.

  * The first option is a map. The map is required to have the keys `:second`, `:minute`, `:hour`,
    `:day`, `:week`, `:month`, and `:year` with the values being the number of seconds below
    which the key defines the time unit difference. This is the default and its value is:

    %{second: 1, month: 2629743.83, day: 86400, year: 31556926, minute: 60, hour: 3600, week: 604800}

  * The second option is to specify a function reference. The function must take four
    arguments as described below.

#### The :derive_unit_from *function*

* The function must take four arguments:
  * `relative`, being the first argument to `to_string/3`.
  * `relative_to` being the value of option `:relative_to` or its default value.
  * `time_difference` being the difference in seconds between `relative`
    and `relative_to`.
  * `unit` being the requested time unit which may be `nil`. If `nil` then
    the time unit must be derived and the `time_difference` scaled to that
    time unit. If specified then the `time_difference` must be scaled to
    the specified time unit.

* The function must return a tuple of the form `{relative, unit}` where
  `relative` is an integer value and `unit` is the appropriate time unit atom.

* See the `Cldr.DateTime.Relative.derive_unit_from/4` function for an example.

### Returns

* `formatted_string` or

* raises an exception.

### Examples

See MicaWeb.Cldr.DateTime.Relative.to_string/2

---

*Consult [api-reference.md](api-reference.md) for complete listing*
