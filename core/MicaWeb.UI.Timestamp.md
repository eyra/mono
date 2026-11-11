# `MicaWeb.UI.Timestamp`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/ui/timestamp.ex#L1)

  Helper functions for displaying timestamps

# `after?`

# `apply_timezone`

# `before?`

# `convert`

# `days_until`

# `format!`

# `format_date!`

# `format_date_short!`

# `format_user_input_date`

# `format_user_input_datetime`

# `from_date_and_time`

# `future?`

# `humanize`

# `humanize`

# `humanize_date`

# `humanize_en`

# `humanize_time`

```elixir
@spec humanize_time(
  {{integer(), pos_integer(), pos_integer()},
   {non_neg_integer(), non_neg_integer(), non_neg_integer()}
   | {non_neg_integer(), non_neg_integer(), non_neg_integer(),
      non_neg_integer() | {non_neg_integer(), non_neg_integer()}}}
  | {integer(), pos_integer(), pos_integer()}
  | %{
      :__struct__ =&gt; Date | DateTime | NaiveDateTime | Time,
      :calendar =&gt; atom(),
      optional(:day) =&gt; pos_integer(),
      optional(:hour) =&gt; non_neg_integer(),
      optional(:microsecond) =&gt; {non_neg_integer(), non_neg_integer()},
      optional(:minute) =&gt; non_neg_integer(),
      optional(:month) =&gt; pos_integer(),
      optional(:second) =&gt; non_neg_integer(),
      optional(:std_offset) =&gt; integer(),
      optional(:time_zone) =&gt; binary(),
      optional(:utc_offset) =&gt; integer(),
      optional(:year) =&gt; integer(),
      optional(:zone_abbr) =&gt; binary()
    }
) :: binary()
```

# `max`

# `naive_from_now`

# `naive_now`

# `now`

# `one_week_after`

# `parse_user_input_date`

# `parse_user_input_datetime`

# `past?`

# `shift_days`

# `shift_minutes`

# `stamp`

# `to_date`

# `tomorrow`

# `yesterday`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
