defmodule EyraUI.Timestamp do
  @moduledoc """
    Helper functions for displaying timestamps
  """
  use Timex
  import EyraUI.Gettext

  def humanize(%NaiveDateTime{} = timestamp) do
    time = Timex.format!(timestamp, "%H:%M", :strftime)

    cond do
      Timex.before?(Timex.shift(Timex.today(), days: -1), NaiveDateTime.to_date(timestamp)) ->
        "#{dgettext("eyra-ui", "timestamp.today")} om #{time}"

      Timex.before?(Timex.shift(Timex.today(), days: -2), NaiveDateTime.to_date(timestamp)) ->
        "#{dgettext("eyra-ui", "timestamp.yesterday")} om #{time}"

      Timex.before?(Timex.shift(Timex.today(), days: -8), NaiveDateTime.to_date(timestamp)) ->
        weekday = Timex.format!(timestamp, "%A", :strftime)
        translated_weekday = Timex.Translator.translate(Gettext.get_locale(), "weekdays", weekday)
        "#{translated_weekday} om #{time}"

      true ->
        datetime = Timex.format!(timestamp, "%A, %B %e,", :strftime) <> time
        "#{datetime}"
    end
  end

  def humanize(_) do
    "?"
  end
end
