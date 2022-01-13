defmodule Systems.Lab.ContextTest do
  use Core.DataCase, async: true
  alias Core.Factories
  alias CoreWeb.UI.Timestamp

  alias Systems.{
    Lab
  }

  setup do
    {:ok,
     member: Factories.insert!(:member),
     lab_tool:
       Factories.insert!(:lab_tool, %{
         time_slots: [
           %{
             start_time:
               Timestamp.tomorrow() |> Timex.set(hour: 9, minute: 0, second: 0, microsecond: 0),
             location: Faker.Lorem.sentence(),
             number_of_seats: 9
           },
           %{
             start_time:
               Timestamp.tomorrow() |> Timex.set(hour: 9, minute: 30, second: 0, microsecond: 0),
             location: Faker.Lorem.sentence(),
             number_of_seats: 9
           }
         ]
       })}
  end

  describe "reserve_time_slot/2" do
    test "creates a reservation", %{lab_tool: lab_tool, member: member} do
      [slot | _] = lab_tool.time_slots
      assert {:ok, reservation} = Lab.Context.reserve_time_slot(slot, member)
      assert reservation.user_id == member.id
      assert reservation.time_slot_id == slot.id
      assert reservation.status == :reserved
    end

    test "creates a reservation when passing in the time slot id", %{
      lab_tool: lab_tool,
      member: member
    } do
      [slot | _] = lab_tool.time_slots
      assert {:ok, reservation} = Lab.Context.reserve_time_slot(slot.id, member)
      assert reservation.user_id == member.id
      assert reservation.time_slot_id == slot.id
      assert reservation.status == :reserved
    end

    test "cancels existing reservation before making a new one", %{
      lab_tool: lab_tool,
      member: member
    } do
      [first_slot | [second_slot | _]] = lab_tool.time_slots
      {:ok, initial_reservation} = Lab.Context.reserve_time_slot(first_slot, member)

      {:ok, new_reservation} = Lab.Context.reserve_time_slot(second_slot, member)

      assert Lab.Context.reservation_for_user(lab_tool, member) == new_reservation
      assert new_reservation != initial_reservation
    end

    test "disallows reservation on time slots that have already started", %{
      member: member
    } do
      lab_tool =
        Factories.insert!(:lab_tool, %{
          time_slots: [
            %{
              start_time: Faker.DateTime.backward(365) |> DateTime.truncate(:second),
              location: Faker.Lorem.sentence(),
              number_of_seats: 9
            }
          ]
        })

      [slot | _] = lab_tool.time_slots
      assert {:error, :time_slot_is_in_the_past} == Lab.Context.reserve_time_slot(slot, member)
    end
  end

  describe "reservation_for_user/2" do
    test "return nil when there is no reservation", %{lab_tool: lab_tool, member: member} do
      assert Lab.Context.reservation_for_user(lab_tool, member) == nil
    end

    test "return the reservation when there is one", %{lab_tool: lab_tool, member: member} do
      [slot | _] = lab_tool.time_slots
      {:ok, reservation} = Lab.Context.reserve_time_slot(slot, member)
      assert Lab.Context.reservation_for_user(lab_tool, member) == reservation
    end

    test "don't return cancelled reservations", %{lab_tool: lab_tool, member: member} do
      [slot | _] = lab_tool.time_slots
      {:ok, _} = Lab.Context.reserve_time_slot(slot, member)
      Lab.Context.cancel_reservation(lab_tool, member)
      assert Lab.Context.reservation_for_user(lab_tool, member) == nil
    end
  end

  describe "cancel_reservation/2" do
    test "return when there is no reservation", %{lab_tool: lab_tool, member: member} do
      assert Lab.Context.cancel_reservation(lab_tool, member) == nil
    end

    test "cancel the reservation when there is one", %{lab_tool: lab_tool, member: member} do
      [slot | _] = lab_tool.time_slots
      {:ok, _} = Lab.Context.reserve_time_slot(slot, member)
      assert Lab.Context.cancel_reservation(lab_tool, member) == nil
    end
  end

  describe "new_day_schedule/1" do
    test "base values if no time slots exist" do
      lab_tool = Factories.insert!(:lab_tool, %{time_slots: []})

      assert %{
               date: date,
               location: "SBE Lab",
               number_of_seats: 8,
               entries: entries
             } = Lab.Context.new_day_model(lab_tool)

      expected_date =
        Timestamp.tomorrow()
        |> Timestamp.to_date()

      assert date |> Timestamp.to_date() == expected_date

      assert [
               %{enabled?: true, start_time: 900, type: :time_slot},
               %{enabled?: true, start_time: 930, type: :time_slot},
               %{enabled?: true, start_time: 1000, type: :time_slot},
               %{enabled?: false, start_time: 1030, type: :time_slot},
               %{type: :break},
               %{enabled?: true, start_time: 1100, type: :time_slot},
               %{enabled?: true, start_time: 1130, type: :time_slot},
               %{enabled?: true, start_time: 1200, type: :time_slot},
               %{enabled?: true, start_time: 1230, type: :time_slot},
               %{type: :break},
               %{enabled?: false, start_time: 1300, type: :time_slot},
               %{enabled?: true, start_time: 1330, type: :time_slot},
               %{enabled?: true, start_time: 1400, type: :time_slot},
               %{enabled?: true, start_time: 1430, type: :time_slot},
               %{type: :break},
               %{enabled?: false, start_time: 1500, type: :time_slot},
               %{enabled?: true, start_time: 1530, type: :time_slot},
               %{enabled?: true, start_time: 1600, type: :time_slot},
               %{enabled?: true, start_time: 1630, type: :time_slot},
               %{enabled?: true, start_time: 1700, type: :time_slot},
               %{type: :break},
               %{enabled?: false, start_time: 1730, type: :time_slot},
               %{enabled?: false, start_time: 1800, type: :time_slot},
               %{enabled?: false, start_time: 1830, type: :time_slot},
               %{enabled?: false, start_time: 1900, type: :time_slot},
               %{enabled?: false, start_time: 1930, type: :time_slot}
             ] = entries
    end

    test "based on last existing time slot", %{lab_tool: %{time_slots: time_slots} = lab_tool} do
      %{
        start_time: start_time,
        location: location,
        number_of_seats: number_of_seats
      } =
        time_slots
        |> Enum.sort_by(& &1.start_time, {:asc, DateTime})
        |> List.last()

      assert {
               :ok,
               %{
                 date: date,
                 location: ^location,
                 number_of_seats: ^number_of_seats,
                 entries: entries
               }
             } = Lab.Context.edit_day_model(lab_tool, start_time)

      expected_date =
        start_time
        |> Timestamp.to_date()

      assert date |> Timestamp.to_date() == expected_date

      assert [
               %{enabled?: true, start_time: 900, type: :time_slot},
               %{enabled?: true, start_time: 930, type: :time_slot},
               %{enabled?: false, start_time: 1000, type: :time_slot},
               %{enabled?: false, start_time: 1030, type: :time_slot},
               %{type: :break},
               %{enabled?: false, start_time: 1100, type: :time_slot},
               %{enabled?: false, start_time: 1130, type: :time_slot},
               %{enabled?: false, start_time: 1200, type: :time_slot},
               %{enabled?: false, start_time: 1230, type: :time_slot},
               %{type: :break},
               %{enabled?: false, start_time: 1300, type: :time_slot},
               %{enabled?: false, start_time: 1330, type: :time_slot},
               %{enabled?: false, start_time: 1400, type: :time_slot},
               %{enabled?: false, start_time: 1430, type: :time_slot},
               %{type: :break},
               %{enabled?: false, start_time: 1500, type: :time_slot},
               %{enabled?: false, start_time: 1530, type: :time_slot},
               %{enabled?: false, start_time: 1600, type: :time_slot},
               %{enabled?: false, start_time: 1630, type: :time_slot},
               %{enabled?: false, start_time: 1700, type: :time_slot},
               %{type: :break},
               %{enabled?: false, start_time: 1730, type: :time_slot},
               %{enabled?: false, start_time: 1800, type: :time_slot},
               %{enabled?: false, start_time: 1830, type: :time_slot},
               %{enabled?: false, start_time: 1900, type: :time_slot},
               %{enabled?: false, start_time: 1930, type: :time_slot}
             ] = entries
    end
  end
end
