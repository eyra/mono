defmodule Core.Lab.ToolsTest do
  use Core.DataCase, async: true
  alias Core.Factories
  alias Core.Lab.Tools

  setup do
    {:ok,
     member: Factories.insert!(:member),
     lab_tool:
       Factories.insert!(:lab_tool, %{
         time_slots: [
           %{
             start_time: Faker.DateTime.forward(365) |> DateTime.truncate(:second),
             location: Faker.Lorem.sentence(),
             number_of_seats: 9
           },
           %{
             start_time: Faker.DateTime.forward(365) |> DateTime.truncate(:second),
             location: Faker.Lorem.sentence(),
             number_of_seats: 9
           }
         ]
       })}
  end

  describe "reserve_time_slot/2" do
    test "creates a reservation", %{lab_tool: lab_tool, member: member} do
      [slot | _] = lab_tool.time_slots
      assert {:ok, reservation} = Tools.reserve_time_slot(slot, member)
      assert reservation.user_id == member.id
      assert reservation.time_slot_id == slot.id
      assert reservation.status == :reserved
    end

    test "creates a reservation when passing in the time slot id", %{
      lab_tool: lab_tool,
      member: member
    } do
      [slot | _] = lab_tool.time_slots
      assert {:ok, reservation} = Tools.reserve_time_slot(slot.id, member)
      assert reservation.user_id == member.id
      assert reservation.time_slot_id == slot.id
      assert reservation.status == :reserved
    end

    test "cancels existing reservation before making a new one", %{
      lab_tool: lab_tool,
      member: member
    } do
      [first_slot | [second_slot | _]] = lab_tool.time_slots
      {:ok, initial_reservation} = Tools.reserve_time_slot(first_slot, member)

      {:ok, new_reservation} = Tools.reserve_time_slot(second_slot, member)

      assert Tools.reservation_for_user(lab_tool, member) == new_reservation
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
      assert {:error, :time_slot_is_in_the_past} == Tools.reserve_time_slot(slot, member)
    end
  end

  describe "reservation_for_user/2" do
    test "return nil when there is no reservation", %{lab_tool: lab_tool, member: member} do
      assert Tools.reservation_for_user(lab_tool, member) == nil
    end

    test "return the reservation when there is one", %{lab_tool: lab_tool, member: member} do
      [slot | _] = lab_tool.time_slots
      {:ok, reservation} = Tools.reserve_time_slot(slot, member)
      assert Tools.reservation_for_user(lab_tool, member) == reservation
    end

    test "don't return cancelled reservations", %{lab_tool: lab_tool, member: member} do
      [slot | _] = lab_tool.time_slots
      {:ok, _} = Tools.reserve_time_slot(slot, member)
      Tools.cancel_reservation(lab_tool, member)
      assert Tools.reservation_for_user(lab_tool, member) == nil
    end
  end

  describe "cancel_reservation/2" do
    test "return when there is no reservation", %{lab_tool: lab_tool, member: member} do
      assert Tools.cancel_reservation(lab_tool, member) == nil
    end

    test "cancel the reservation when there is one", %{lab_tool: lab_tool, member: member} do
      [slot | _] = lab_tool.time_slots
      {:ok, _} = Tools.reserve_time_slot(slot, member)
      assert Tools.cancel_reservation(lab_tool, member) == nil
    end
  end
end
