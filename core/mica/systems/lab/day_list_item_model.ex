defmodule Systems.Lab.DayListItemModel do
  use Ecto.Schema

  alias CoreWeb.UI.Timestamp

  embedded_schema do
    field(:enabled?, :boolean)
    field(:date, :date)
    field(:location, :string)
    field(:number_of_timeslots, :integer)
    field(:number_of_seats, :integer)
  end

  def parse(time_slots) do
    time_slots
    |> prepare()
    |> create_day_list_items()
  end

  defp create_day_list_items(days) do
    Enum.map(days, &create_day_list_item(&1))
  end

  defp create_day_list_item(%{date: date, location: location, time_slots: time_slots}) do
    number_of_timeslots = Enum.count(time_slots)

    number_of_seats =
      time_slots
      |> Enum.reduce(0, &(&2 + &1.number_of_seats))

    enabled? = not Timestamp.past?(date)

    %{
      enabled?: enabled?,
      date: date,
      location: location,
      number_of_timeslots: number_of_timeslots,
      number_of_seats: number_of_seats
    }
  end

  defp prepare(time_slots) when is_list(time_slots) do
    Enum.reduce(time_slots, [], fn time_slot, acc ->
      prepare(time_slot, acc)
    end)
  end

  defp prepare(%{enabled?: false} = _time_slot, acc), do: acc

  defp prepare(%{start_time: start_time} = time_slot, acc) do
    date = Timestamp.to_date(start_time)

    acc
    |> create_day_if_needed(date, time_slot)
    |> add_time_slot(date, time_slot)
  end

  defp create_day_if_needed(acc, date, %{location: location}) do
    case find_day(acc, date, location) do
      nil ->
        acc ++
          [
            %{
              date: date,
              location: location,
              time_slots: []
            }
          ]

      _ ->
        acc
    end
  end

  defp add_time_slot(days, date, %{location: location} = time_slot) do
    Enum.map(
      days,
      &if is_day?(&1, date, location) do
        add_time_slot(&1, time_slot)
      else
        &1
      end
    )
  end

  defp add_time_slot(%{time_slots: time_slots} = day, timeslot) do
    %{day | time_slots: time_slots ++ [timeslot]}
  end

  defp find_day([], _, _), do: nil

  defp find_day([_ | _] = days, date, location) do
    days |> Enum.find_value(&is_day?(&1, date, location))
  end

  # credo:disable-for-next-line
  defp is_day?(day, date, location) do
    Date.compare(day.date, date) == :eq and day.location == location
  end
end
