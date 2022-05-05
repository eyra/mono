defmodule Systems.Lab.Context do
  import Ecto.Query, warn: false
  alias CoreWeb.UI.Timestamp
  alias Systems.Lab.VUDaySchedule, as: DaySchedule

  alias Core.Repo
  alias Ecto.Multi

  alias Frameworks.{
    Signal
  }

  alias Systems.{
    Lab
  }

  alias Core.Accounts.User

  def get(id, preload \\ []) do
    from(lab_tool in Lab.ToolModel,
      preload: ^preload
    )
    |> Repo.get!(id)
    |> filter_double_time_slots()
  end

  def create_tool(attrs, auth_node) do
    %Lab.ToolModel{}
    |> Lab.ToolModel.changeset(:mount, attrs)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert()
  end

  def copy(%Lab.ToolModel{} = tool, auth_node) do
    %Lab.ToolModel{}
    |> Lab.ToolModel.changeset(:copy, Map.from_struct(tool))
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert!()
  end

  def update_tool(changeset) do
    with {:ok, %{tool: tool} = result} <-
           Multi.new()
           |> Multi.update(:tool, changeset)
           |> Repo.transaction() do
      Signal.Context.dispatch!(:lab_tool_updated, tool)
      {:ok, result}
    end
  end

  def get_time_slot(id, preload \\ []) do
    from(ts in Lab.TimeSlotModel,
      where: ts.id == ^id,
      preload: ^preload
    )
    |> Repo.one()
  end

  def get_time_slots(id, preload \\ []) do
    from(ts in Lab.TimeSlotModel,
      where: ts.tool_id == ^id and ts.enabled? == true,
      order_by: [asc: :start_time, asc: :id],
      preload: ^preload
    )
    |> Repo.all()
    |> filter_double_time_slots()
  end


  def get_available_time_slots(id) do
    get_time_slots(id, [:reservations])
    |> Enum.filter(&(&1.number_of_seats > Enum.count(&1.reservations)))
  end

  def new_day_model(%Lab.ToolModel{id: id}) do
    time_slots = get_time_slots(id)
    base_values = DaySchedule.base_values(time_slots)

    date =
      base_values
      |> Map.get(:start_time)
      |> Timestamp.shift_days(1)
      |> Timestamp.to_date()

    %Lab.DayModel{
      tool_id: id,
      date: date,
      date_editable?: true,
      location: Map.get(base_values, :location),
      number_of_seats: Map.get(base_values, :number_of_seats),
      entries: DaySchedule.entries()
    }
  end

  def duplicate_day_model(%Lab.ToolModel{id: id}, %{date: date, location: location}) do
    all_time_slots = get_time_slots(id, [:reservations])
    base_values = DaySchedule.base_values(all_time_slots)

    time_slots =
      all_time_slots
      |> Enum.filter(
        &(Date.compare(Timestamp.to_date(&1.start_time), date) == :eq and
            &1.location == location)
      )

    entries = time_slots |> DaySchedule.entries()

    number_of_seats =
      time_slots
      |> Enum.reduce(
        0,
        fn %{number_of_seats: number_of_seats}, acc ->
          if number_of_seats > acc do
            number_of_seats
          else
            acc
          end
        end
      )

    new_date =
      base_values
      |> Map.get(:start_time)
      |> Timestamp.shift_days(1)
      |> Timestamp.to_date()

    %Lab.DayModel{
      tool_id: id,
      date: new_date,
      date_editable?: true,
      location: location,
      number_of_seats: number_of_seats,
      entries: entries
    }
  end

  def edit_day_model(%Lab.ToolModel{id: id}, %{date: date, location: location}) do
    time_slots =
      get_time_slots(id, [:reservations])
      |> Enum.filter(
        &(Date.compare(Timestamp.to_date(&1.start_time), date) == :eq and
            &1.location == location)
      )

    date_editable? = Timestamp.future?(date)
    entries = time_slots |> DaySchedule.entries()

    number_of_seats =
      time_slots
      |> Enum.reduce(
        0,
        fn %{number_of_seats: number_of_seats}, acc ->
          if number_of_seats > acc do
            number_of_seats
          else
            acc
          end
        end
      )

    %Lab.DayModel{
      tool_id: id,
      date: date,
      date_editable?: date_editable?,
      location: location,
      number_of_seats: number_of_seats,
      entries: entries
    }
  end

  def submit_day_model(
        %Lab.ToolModel{} = tool,
        %{
          date: og_date,
          location: og_location
        },
        %{
          date: date,
          location: location,
          entries: entries
        }
      ) do
    entries
    |> Enum.each(&submit_day_entry(&1, tool, og_date, og_location, date, location))

    Signal.Context.dispatch!(:lab_tool_updated, tool)
  end

  defp submit_day_entry(
         %{
           type: :time_slot,
           start_time: start_time,
           number_of_seats: number_of_seats,
           enabled?: enabled?
         },
         %Lab.ToolModel{} = tool,
         og_date,
         og_location,
         date,
         location
       ) do
    og_start_time = Timestamp.from_date_and_time(og_date, start_time)
    start_time = Timestamp.from_date_and_time(date, start_time)

    tool
    |> time_slot_query(og_start_time, og_location)
    |> Repo.all()
    |> List.first()
    |> submit_time_slot(tool, %{
      enabled?: enabled?,
      start_time: start_time,
      location: location,
      number_of_seats: number_of_seats
    })
  end

  defp submit_day_entry(_, _, _, _, _, _), do: :noop

  defp submit_time_slot(nil, _tool, %{enabled?: false}), do: nil

  defp submit_time_slot(nil, tool, attrs) do
    create_time_slot(tool, attrs)
  end

  defp submit_time_slot(time_slot, _tool, attrs) do
    update_time_slot(time_slot, attrs)
  end

  def remove_day(%Lab.ToolModel{} = tool, %{date: date, location: location}) do
    from = Timestamp.from_date_and_time(date, 0)
    to = Timestamp.from_date_and_time(date, 0) |> Timestamp.shift_days(1)

    with {count, nil} <-
           tool
           |> time_slot_query(from, to, location)
           |> Repo.update_all(set: [enabled?: false]) do
      if count > 0 do
        Signal.Context.dispatch!(:lab_tool_updated, tool)
      end

      {count, nil}
    end
  end

  def filter_double_time_slots(%Lab.ToolModel{} = tool) do
    if Ecto.assoc_loaded?(tool.time_slots) do
      filtered_time_slots = filter_double_time_slots(tool.time_slots)

      tool
      |> Map.put(:time_slots, filtered_time_slots)
    else
      tool
    end
  end

  def filter_double_time_slots(time_slots) do
    time_slots
    |> Enum.reduce([], fn ts, acc ->
      if acc |> Enum.find(&DateTime.compare(&1.start_time, ts.start_time) == :eq)  do
        acc
      else
        [ts | acc]
      end
    end)
    |> Enum.reverse()
  end

  defp create_time_slot(%Lab.ToolModel{} = tool, attrs) do
    %Lab.TimeSlotModel{}
    |> Lab.TimeSlotModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:tool, tool)
    |> Repo.insert()
  end

  defp update_time_slot(%Lab.TimeSlotModel{} = time_slot, attrs) do
    time_slot
    |> Lab.TimeSlotModel.changeset(attrs)
    |> Repo.update!()
  end

  defp time_slot_query(%Lab.ToolModel{id: tool_id}, start_time, location) do
    from(ts in Lab.TimeSlotModel,
      where:
        ts.tool_id == ^tool_id and
          ts.start_time == ^start_time and
          ts.location == ^location
    )
  end

  defp time_slot_query(%Lab.ToolModel{id: tool_id}, from, to, location) do
    from(ts in Lab.TimeSlotModel,
      where:
        ts.tool_id == ^tool_id and
          ts.start_time >= ^from and
          ts.start_time < ^to and
          ts.location == ^location
    )
  end

  def reserve_time_slot(time_slot_id, %User{} = user) when is_integer(time_slot_id) do
    Lab.TimeSlotModel
    |> Repo.get(time_slot_id)
    |> reserve_time_slot(user)
  end

  def reserve_time_slot(%Lab.TimeSlotModel{tool_id: tool_id} = time_slot, %User{} = user) do
    cancel_reservations(time_slot.tool_id, user)

    with {:ok, reservation} <-
           %Lab.ReservationModel{}
           |> Lab.ReservationModel.changeset(%{
             status: :reserved,
             user_id: user.id,
             time_slot_id: time_slot.id
           })
           |> Repo.insert(
             conflict_target: [:user_id, :time_slot_id],
             on_conflict: {:replace, [:status]}
           ) do
      tool = get(tool_id)

      Signal.Context.dispatch!(:lab_reservation_created, %{
        tool: tool,
        user: user,
        time_slot: time_slot
      })

      {:ok, reservation}
    end
  end

  def reservation_for_user(%Lab.ToolModel{} = tool, %User{} = user) do
    reservation_query(tool.id, user)
    |> Repo.one()
  end

  def cancel_reservation(%Lab.ToolModel{} = tool, %User{} = user) do
    cancel_reservations(tool.id, user)
  end

  defp cancel_reservations(tool_id, %User{} = user) when is_integer(tool_id) do
    query = reservation_query(tool_id, user)

    with {update_count, _} <- Repo.update_all(query, set: [status: :cancelled]) do
      if update_count > 0 do
        Signal.Context.dispatch!(:lab_reservations_cancelled, %{tool: get(tool_id), user: user})
      end

      unless update_count < 2 do
        throw(:more_than_one_reservation_should_not_happen)
      end
    end
  end

  defp reservation_query(tool_id, %User{} = user) when is_integer(tool_id) do
    from(reservation in Lab.ReservationModel,
      join: time_slot in Lab.TimeSlotModel,
      on: [id: reservation.time_slot_id],
      join: tool in Lab.ToolModel,
      on: [id: time_slot.tool_id],
      where:
        reservation.user_id == ^user.id and tool.id == ^tool_id and
          reservation.status == :reserved
    )
  end

  def ready?(%Lab.ToolModel{} = lab_tool) do
    changeset =
      %Lab.ToolModel{}
      |> Lab.ToolModel.operational_changeset(Map.from_struct(lab_tool))

    changeset.valid?
  end
end

defimpl Core.Persister, for: Systems.Lab.ToolModel do
  def save(_tool, changeset) do
    Systems.Lab.Context.update_tool(changeset)
  end
end
