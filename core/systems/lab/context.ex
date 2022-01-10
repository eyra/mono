defmodule Systems.Lab.Context do
  import Ecto.Query, warn: false
  alias CoreWeb.UI.Timestamp
  alias Systems.Lab.VUDaySchedule, as: DaySchedule

  alias Core.Repo

  alias Systems.{
    Lab
  }

  alias Core.Accounts.User

  def get(id, opts \\ []) do
    from(lab_tool in Lab.ToolModel,
      preload: ^Keyword.get(opts, :preload, [])
    )
    |> Repo.get!(id)
  end

  def create_tool(attrs, auth_node) do
    %Lab.ToolModel{}
    |> Lab.ToolModel.changeset(:mount, attrs)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert()
  end

  def get_time_slots(id, preload \\ []) do
    from(ts in Lab.TimeSlotModel,
      where: ts.tool_id == ^id,
      order_by: {:asc, :start_time},
      preload: ^preload
    )
    |> Repo.all()
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
      date: date,
      date_editable?: true,
      location: Map.get(base_values, :location),
      number_of_seats: Map.get(base_values, :number_of_seats),
      entries: DaySchedule.entries()
    }
  end

  def edit_day_model(%Lab.ToolModel{id: id}, date) do
    date_time_slots =
      get_time_slots(id, [:reservations])
      |> Enum.filter(&(Date.compare(Timestamp.to_date(&1.start_time), date) == :eq))

    edit_day_model(date_time_slots, date)
  end

  def edit_day_model([_ | _] = time_slots, date) do
    base_values = DaySchedule.base_values(time_slots)

    {
      :ok,
      %Lab.DayModel{
        date: date,
        date_editable?: Timestamp.future?(date),
        location: Map.get(base_values, :location),
        number_of_seats: Map.get(base_values, :number_of_seats),
        entries: DaySchedule.entries(time_slots)
      }
    }
  end

  def edit_day_model(_, date), do: {:error, "No time slots available on #{date}"}

  def process_day_model(%Lab.ToolModel{} = tool, %{date: date, location: location, entries: entries}) do
    entries
    |> Enum.each(&process_day_entry(&1, tool, date, location))
  end

  defp process_day_entry(%{type: :time_slot, start_time: start_time, number_of_seats: number_of_seats, enabled?: enabled?}, %Lab.ToolModel{} = tool, date, location) do
    start_date_time = Timestamp.from_date_and_time(date, start_time)

    exists? =  time_slot_exists?(tool, start_date_time, location)

    case {exists?, enabled?} do
      {false , false} ->
        :noop
      {false , true} ->
        create_time_slot(tool, %{start_time: start_date_time, location: location, number_of_seats: number_of_seats})
      {true , true} ->
        # update (reset possible soft delete)
        :noop
      {true , false} ->
        # soft delete
        :noop
      end
  end
  defp process_day_entry(_, _, _, _), do: :noop

  defp create_time_slot(%Lab.ToolModel{} = tool, attrs) do
    %Lab.TimeSlotModel{}
    |> Lab.TimeSlotModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:tool, tool)
    |> Repo.insert()
  end

  defp time_slot_exists?(%Lab.ToolModel{} = tool, start_time, location) do
    tool
    |> time_slot_query(start_time, location)
    |> Repo.exists?()
  end

  defp time_slot_query(%Lab.ToolModel{id: tool_id}, start_time, location)  do
    from(ts in Lab.TimeSlotModel,
      where:
        ts.tool_id == ^tool_id and
        ts.start_time == ^start_time and
        ts.location == ^location
    )
  end

  def reserve_time_slot(time_slot_id, %User{} = user) when is_integer(time_slot_id) do
    Lab.TimeSlotModel
    |> Repo.get(time_slot_id)
    |> reserve_time_slot(user)
  end

  def reserve_time_slot(%Lab.TimeSlotModel{} = time_slot, %User{} = user) do
    # Disallow reservations for past time slots
    if DateTime.compare(time_slot.start_time, DateTime.now!("Etc/UTC")) == :lt do
      {:error, :time_slot_is_in_the_past}
    else
      # First cancel any existing reservations for the same lab
      cancel_reservations(time_slot.tool_id, user)

      %Lab.ReservationModel{}
      |> Lab.ReservationModel.changeset(%{
        status: :reserved,
        user_id: user.id,
        time_slot_id: time_slot.id
      })
      |> Repo.insert()
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
    {update_count, _} = Repo.update_all(query, set: [status: :cancelled])

    unless update_count < 2 do
      throw(:more_than_one_reservation_should_not_happen)
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
