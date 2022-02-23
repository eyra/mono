defmodule Systems.Lab.DayListItemModelTest do
  use Core.DataCase, async: true
  alias Core.Factories

  alias Systems.{
    Lab
  }

  describe "parse/1" do
    test "1 time slot" do
      lab_tool = Factories.insert!(:lab_tool)

      time_slot =
        Factories.insert!(:time_slot, %{
          lab_tool: lab_tool,
          start_time: ~U[2022-01-01 09:00:00Z],
          location: "SBE",
          number_of_seats: 8
        })

      [day_list_item] = Lab.DayListItemModel.parse([time_slot])

      assert %{
               date: ~D[2022-01-01],
               enabled?: false,
               location: "SBE",
               number_of_seats: 8,
               number_of_timeslots: 1
             } = day_list_item
    end

    test "2 time slots, 1 date, 1 location" do
      lab_tool = Factories.insert!(:lab_tool)

      time_slot1 =
        Factories.insert!(:time_slot, %{
          lab_tool: lab_tool,
          start_time: ~U[2022-01-01 09:00:00Z],
          location: "SBE",
          number_of_seats: 8
        })

      time_slot2 =
        Factories.insert!(:time_slot, %{
          lab_tool: lab_tool,
          start_time: ~U[2022-01-01 10:00:00Z],
          location: "SBE",
          number_of_seats: 10
        })

      [item] = Lab.DayListItemModel.parse([time_slot1, time_slot2])

      assert %{
               date: ~D[2022-01-01],
               enabled?: false,
               location: "SBE",
               number_of_seats: 18,
               number_of_timeslots: 2
             } = item
    end

    test "4 time slots, 2 dates, 1 location" do
      lab_tool = Factories.insert!(:lab_tool)

      time_slot1 =
        Factories.insert!(:time_slot, %{
          lab_tool: lab_tool,
          start_time: ~U[2022-01-01 09:00:00Z],
          location: "SBE",
          number_of_seats: 8
        })

      time_slot2 =
        Factories.insert!(:time_slot, %{
          lab_tool: lab_tool,
          start_time: ~U[2022-01-01 10:00:00Z],
          location: "SBE",
          number_of_seats: 10
        })

      time_slot3 =
        Factories.insert!(:time_slot, %{
          lab_tool: lab_tool,
          start_time: ~U[2022-01-02 09:00:00Z],
          location: "SBE",
          number_of_seats: 3
        })

      time_slot4 =
        Factories.insert!(:time_slot, %{
          lab_tool: lab_tool,
          start_time: ~U[2022-01-02 10:00:00Z],
          location: "SBE",
          number_of_seats: 4
        })

      [item1, item2] =
        Lab.DayListItemModel.parse([time_slot1, time_slot2, time_slot3, time_slot4])

      assert %{
               date: ~D[2022-01-01],
               enabled?: false,
               location: "SBE",
               number_of_seats: 18,
               number_of_timeslots: 2
             } = item1

      assert %{
               date: ~D[2022-01-02],
               enabled?: false,
               location: "SBE",
               number_of_seats: 7,
               number_of_timeslots: 2
             } = item2
    end

    test "4 time slots, 1 date, 2 locations" do
      lab_tool = Factories.insert!(:lab_tool)

      time_slot1 =
        Factories.insert!(:time_slot, %{
          lab_tool: lab_tool,
          start_time: ~U[2022-01-01 09:00:00Z],
          location: "SBE 1",
          number_of_seats: 8
        })

      time_slot2 =
        Factories.insert!(:time_slot, %{
          lab_tool: lab_tool,
          start_time: ~U[2022-01-01 10:00:00Z],
          location: "SBE 1",
          number_of_seats: 10
        })

      time_slot3 =
        Factories.insert!(:time_slot, %{
          lab_tool: lab_tool,
          start_time: ~U[2022-01-01 09:00:00Z],
          location: "SBE 2",
          number_of_seats: 3
        })

      time_slot4 =
        Factories.insert!(:time_slot, %{
          lab_tool: lab_tool,
          start_time: ~U[2022-01-01 10:00:00Z],
          location: "SBE 2",
          number_of_seats: 4
        })

      [item1, item2] =
        Lab.DayListItemModel.parse([time_slot1, time_slot2, time_slot3, time_slot4])

      assert %{
               date: ~D[2022-01-01],
               enabled?: false,
               location: "SBE 1",
               number_of_seats: 18,
               number_of_timeslots: 2
             } = item1

      assert %{
               date: ~D[2022-01-01],
               enabled?: false,
               location: "SBE 2",
               number_of_seats: 7,
               number_of_timeslots: 2
             } = item2
    end
  end
end
