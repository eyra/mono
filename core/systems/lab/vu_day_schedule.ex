defmodule Systems.Lab.VUDaySchedule do
  alias CoreWeb.UI.Timestamp

  alias Systems.{
    Lab
  }

  @time_slots [
    900,
    930,
    1000,
    1030,
    1100,
    1130,
    1200,
    1230,
    1300,
    1330,
    1400,
    1430,
    1500,
    1530,
    1600,
    1630,
    1700,
    1730,
    1800,
    1830,
    1900,
    1930
  ]

  @breaks [1030, 1230, 1430, 1700]

  @default_disabled [1030, 1300, 1500, 1730, 1800, 1830, 1900, 1930]

  def entries(time_slots) do
    entries()
    |> Enum.map(&map_entry(&1, time_slots))
  end

  def entries do
    @time_slots
    |> Enum.map(fn start_time ->
      %{
        type: :time_slot,
        enabled?: start_time not in @default_disabled,
        start_time: start_time,
        number_of_reservations: 0
      }
    end)
    |> insert_breaks()
  end

  defp insert_breaks(entries) do
    @breaks
    |> Enum.reverse()
    |> Enum.map(fn break -> Enum.find_index(entries, &(&1.start_time == break)) end)
    |> Enum.reduce(entries, fn break_index, acc ->
      {hd, tl} = Enum.split(acc, break_index + 1)
      hd ++ [%{type: :break} | tl]
    end)
  end

  defp map_entry(%{type: :time_slot, start_time: start_time} = time_slot, existing_time_slots) do
    existing_time_slot =
      Enum.find(existing_time_slots, nil, &(time_as_integer(&1.start_time) == start_time))

    enabled? = existing_time_slot != nil
    number_of_reservations = number_of_reservations(existing_time_slot)

    %{time_slot | enabled?: enabled?, number_of_reservations: number_of_reservations}
  end

  defp map_entry(entry, _), do: entry

  defp number_of_reservations(nil), do: 0

  defp number_of_reservations(%Lab.TimeSlotModel{reservations: reservations}) do
    reservations
    |> Enum.filter(&(&1.status != :cancelled))
    |> Enum.count()
  end

  def base_values(time_slots) do
    time_slots
    |> List.last(%{
      start_time: Timestamp.now(),
      location: "SBE Lab",
      number_of_seats: 8
    })
  end

  defp time_as_integer(%DateTime{hour: hour, minute: minute}) do
    hour * 100 + minute
  end
end
