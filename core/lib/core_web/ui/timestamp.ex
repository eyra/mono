defmodule Coreweb.UI.Timestamp do
  @moduledoc """
    Helper functions for displaying timestamps
  """
  use Timex
  import CoreWeb.Gettext

  def locale do
    Gettext.get_locale(CoreWeb.Gettext)
  end

  def humanize(%NaiveDateTime{} = timestamp) do
    time = Timex.format!(timestamp, "%H:%M", :strftime)

    cond do
      Timex.before?(Timex.shift(Timex.today(), days: -1), NaiveDateTime.to_date(timestamp)) ->
        "#{dgettext("eyra-ui", "timestamp.today")} #{dgettext("eyra-ui", "timestamp.at")}: #{time}"

      Timex.before?(Timex.shift(Timex.today(), days: -2), NaiveDateTime.to_date(timestamp)) ->
        "#{dgettext("eyra-ui", "timestamp.yesterday")} #{dgettext("eyra-ui", "timestamp.at")}: #{time}"

      Timex.before?(Timex.shift(Timex.today(), days: -8), NaiveDateTime.to_date(timestamp)) ->
        weekday = Timex.format!(timestamp, "%A", :strftime)
        translated_weekday = Timex.Translator.translate(locale(), "weekdays", weekday)
        "#{translated_weekday} #{dgettext("eyra-ui", "timestamp.at")} #{time}"

      true ->
        weekday = Timex.format!(timestamp, "%A", :strftime)
        translated_weekday = Timex.Translator.translate(locale(), "weekdays", weekday)
        month = Timex.format!(timestamp, "%B", :strftime)
        translated_month = Timex.Translator.translate(locale(), "months", month)
        day_of_month = Timex.format!(timestamp, "%e", :strftime)

        translated_day_of_month =
          Timex.Translator.translate(locale(), "days_of_month", day_of_month)

        if locale() == "nl" do
          "#{translated_weekday}, #{translated_day_of_month} #{translated_month}"
        else
          "#{translated_weekday}, #{translated_month} #{translated_day_of_month}"
        end
    end
  end

  def humanize(_) do
    "?"
  end

  # FIXME: Replace hard coded Timezone with user settings
  def apply_timezone(%NaiveDateTime{} = timestamp, timezone \\ "Europe/Amsterdam") do
    tz_offset =
      Timex.timezone(timezone, timestamp)
      |> Timex.Timezone.total_offset()

    Timex.shift(timestamp, seconds: tz_offset)
  end
end
