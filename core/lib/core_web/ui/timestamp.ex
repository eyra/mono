defmodule CoreWeb.UI.Timestamp do
  @moduledoc """
    Helper functions for displaying timestamps
  """
  use Timex
  import CoreWeb.Gettext

  def to_date(%{year: year, month: month, day: day}) do
    %Date{
      year: year,
      month: month,
      day: day
    }
  end

  def from_date_and_time(%Date{} = date, time) when is_integer(time) do
    hour = (time / 100) |> trunc()
    minute = rem(time, 100)

    from_date_and_time(date, Time.new!(hour, minute, 0))
  end

  def from_date_and_time(%Date{} = date, %Time{} = time) do
    DateTime.new!(date, time)
  end

  def now(timezone \\ "Etc/UTC") do
    DateTime.now!(timezone)
  end

  def tomorrow(timezone \\ "Etc/UTC") do
    DateTime.now!(timezone)
    |> shift_days(1)
  end

  def yesterday(timezone \\ "Etc/UTC") do
    DateTime.now!(timezone)
    |> shift_days(-1)
  end

  def naive_now() do
    now()
    |> DateTime.to_naive()
    |> NaiveDateTime.truncate(:second)
  end

  def naive_from_now(shift_minutes) do
    now()
    |> shift_minutes(shift_minutes)
    |> DateTime.to_naive()
    |> NaiveDateTime.truncate(:second)
  end

  def one_week_after(date) when is_binary(date) do
    one_week_after(parse_user_input_date(date))
  end

  def one_week_after(date) do
    date |> Timex.shift(days: 7)
  end

  def shift_minutes(date, minutes) do
    date |> Timex.shift(minutes: minutes)
  end

  def shift_days(date, days) do
    date |> Timex.shift(days: days)
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

  def after?(%Date{} = date1, %DateTime{} = date2) do
    Date.compare(date1, to_date(date2)) == :gt
  end

  def after?(%DateTime{} = date1, %DateTime{} = date2) do
    DateTime.compare(date1, date2) == :gt
  end

  def before?(date1, date2) when is_binary(date1) and is_binary(date2) do
    before?(
      parse_user_input_date(date1),
      parse_user_input_date(date2)
    )
  end

  def before?(%Date{} = date1, %DateTime{} = date2) do
    Date.compare(date1, to_date(date2)) == :lt
  end

  def before?(%DateTime{} = date1, %DateTime{} = date2) do
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

  def humanize_time(timestamp) do
    Timex.format!(timestamp, "%H:%M", :strftime)
  end

  def humanize_date(%Date{} = date) do
    Timex.format!(date, "%A %d %b '%y", :strftime)
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
        "#{weekday} #{dgettext("eyra-ui", "timestamp.at")} #{time}"

      true ->
        weekday = Timex.format!(timestamp, "%A", :strftime)
        month = Timex.format!(timestamp, "%B", :strftime)
        day_of_month = Timex.format!(timestamp, "%e", :strftime)

        if Timex.Translator.current_locale() == "nl" do
          "#{weekday}, #{day_of_month} #{month}"
        else
          "#{weekday}, #{month} #{day_of_month}"
        end
    end
  end

  def humanize(_) do
    "?"
  end

  def humanize_en(%NaiveDateTime{} = timestamp) do
    time = Timex.format!(timestamp, "%H:%M", :strftime)

    cond do
      Timex.before?(Timex.shift(Timex.today(), days: -1), NaiveDateTime.to_date(timestamp)) ->
        "Today at #{time}"

      Timex.before?(Timex.shift(Timex.today(), days: -2), NaiveDateTime.to_date(timestamp)) ->
        "Yesterday at #{time}"

      true ->
        month = Timex.lformat!(timestamp, "%B", "en", :strftime)
        day_of_month = Timex.lformat!(timestamp, "%e", "en", :strftime)
        "#{month} #{day_of_month} at #{time}"
    end
  end

  # FIXME: Replace hard coded Timezone with user settings
  def apply_timezone(%NaiveDateTime{} = timestamp, timezone \\ "Europe/Amsterdam") do
    tz_offset =
      Timex.timezone(timezone, timestamp)
      |> Timex.Timezone.total_offset()

    Timex.shift(timestamp, seconds: tz_offset)
  end
end
