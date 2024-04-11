defmodule CoreWeb.Ui.TimestampTest do
  use ExUnit.Case, async: true

  alias CoreWeb.UI.Timestamp

  describe "convert/2" do
    test "from Europe/Amsterdam to Etc/UTC" do
      now =
        %{
          hour: hour,
          std_offset: std_offset,
          utc_offset: utc_offset
        } = Timestamp.now("Europe/Amsterdam")

      assert 1 = hours(utc_offset)

      offset_in_hours = hours(utc_offset + std_offset)
      expected_hour = apply_offset(hour, -offset_in_hours)

      assert %{
               hour: ^expected_hour
             } = Timestamp.convert(now)
    end

    test "from Etc/UTC to America/New_York" do
      now =
        %{
          hour: hour
        } = Timestamp.now("Etc/UTC")

      assert %{
               hour: expected_hour,
               std_offset: std_offset,
               utc_offset: utc_offset
             } = Timestamp.convert(now, "America/New_York")

      assert -5 = hours(utc_offset)

      offset_in_hours = hours(utc_offset + std_offset)
      assert expected_hour == apply_offset(hour, offset_in_hours)
    end

    test "Etc/UTC to Etc/UTC" do
      now =
        %{
          hour: hour
        } = Timestamp.now("Etc/UTC")

      assert %{
               hour: ^hour
             } = Timestamp.convert(now, "Etc/UTC")
    end
  end

  defp hours(seconds) do
    Integer.floor_div(seconds, 3600)
  end

  def apply_offset(hour, offset) do
    Integer.mod(hour + offset, 23)
  end
end
