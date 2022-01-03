defmodule Systems.Lab.VUDaySchedule do
  import Frameworks.Utility.List
  alias CoreWeb.UI.Timestamp

  @time_slots [
    900,
    930,
    1000,
    1030,
    1100,
    1130,
    1200,
    1230,
    1330,
    1400,
    1430,
    1500,
    1530,
    1600,
    1630,
    1700,
    1800,
    1830,
    1900,
    1930
  ]

  def entries do
    @time_slots
    |> Enum.map(fn start_time ->
      %{
        type: :time_slot,
        enabled: start_time <= 1700,
        start_time: start_time
      }
    end)
    |> insert_breaks()
  end

  def entries(time_slots) do
    entries()
    |> Enum.map(&map_entry(&1, time_slots))
  end

  defp map_entry(%{type: :time_slot, start_time: start_time} = time_slot, existing_time_slots) do
    found? =
      Enum.find(existing_time_slots, nil, &(time_as_integer(&1.start_time) == start_time)) != nil

    time_slot |> Map.put(:enabled, found?)
  end

  defp map_entry(entry, _), do: entry

  def base_values(time_slots) do
    time_slots
    |> List.last(%{
      start_time: Timestamp.now(),
      location: "SBE Lab",
      number_of_seats: 8
    })
  end

  defp insert_breaks(entries) do
    entries |> insert_at_every(4, fn -> %{type: :break} end)
  end

  defp time_as_integer(%DateTime{hour: hour, minute: minute}) do
    hour * 100 + minute
  end
end
