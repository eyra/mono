defmodule CoreWeb.UI.Timestamp do
  @moduledoc """
    Helper functions for displaying timestamps
  """
  use Timex
  import CoreWeb.Gettext

  def locale do
    Gettext.get_locale(CoreWeb.Gettext)
  end

  def now(timezone \\ "Etc/UTC") do
    DateTime.now!(timezone)
  end

  def one_week_after(date) when is_binary(date) do
    one_week_after(parse_user_input_date(date))
  end

  def one_week_after(date) do
    date |> Timex.shift(days: 7)
  end

  def future?(date) when is_binary(date) do
    after?(parse_user_input_date(date), now())
  end

  def future?(date) do
    after?(date, now())
  end

  def past?(date) when is_binary(date) do
    before?(parse_user_input_date(date), now())
  end

  def past?(date) do
    before?(date, now())
  end

  def after?(date1, date2) when is_binary(date1) and is_binary(date2) do
    after?(
      parse_user_input_date(date1),
      parse_user_input_date(date2)
    )
  end

  def after?(date1, date2) do
    DateTime.compare(date1, date2) == :gt
  end

  def before?(date1, date2) when is_binary(date1) and is_binary(date2) do
    before?(
      parse_user_input_date(date1),
      parse_user_input_date(date2)
    )
  end

  def before?(date1, date2) do
    DateTime.compare(date1, date2) == :lt
  end

  def parse_user_input_date(input, timezone \\ "Etc/UTC")

  def parse_user_input_date(nil, _), do: nil
  def parse_user_input_date("", _), do: nil

  def parse_user_input_date(input, timezone) do
    case Timex.parse(input, "%Y-%m-%d", :strftime) do
      {:ok, result} -> DateTime.from_naive!(result, timezone)
      _ -> nil
    end
  end

  def format_user_input_date(%DateTime{} = timestamp) do
    case Timex.format(timestamp, "%Y-%m-%d", :strftime) do
      {:ok, result} -> result
      _ -> nil
    end
  end

  def humanize(%NaiveDateTime{} = timestamp) do
    time = Timex.format!(timestamp, "%H:%M", :strftime)

    cond do
      Timex.before?(Timex.shift(Timex.today(), days: -1), NaiveDateTime.to_date(timestamp)) ->
        "#{dgettext("eyra-ui", "timestamp.today")} #{dgettext("eyra-ui", "timestamp.at")} #{time}"

      Timex.before?(Timex.shift(Timex.today(), days: -2), NaiveDateTime.to_date(timestamp)) ->
        "#{dgettext("eyra-ui", "timestamp.yesterday")} #{dgettext("eyra-ui", "timestamp.at")} #{time}"

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
