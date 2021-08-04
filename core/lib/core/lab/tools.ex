defmodule Core.Lab.Tools do
  import Ecto.Query, warn: false
  alias Core.Repo

  alias Core.Lab.{Tool, Reservation, TimeSlot}
  alias Core.Accounts.User

  def get(id, opts \\ []) do
    from(lab_tool in Tool,
      preload: ^Keyword.get(opts, :preload, [])
    )
    |> Repo.get!(id)
  end

  def get_by_promotion(promotion_id) do
    from(t in Tool,
      where: t.promotion_id == ^promotion_id
    )
    |> Repo.one()
  end

  def reserve_time_slot(time_slot_id, %User{} = user) when is_integer(time_slot_id) do
    TimeSlot
    |> Repo.get(time_slot_id)
    |> reserve_time_slot(user)
  end

  def reserve_time_slot(%TimeSlot{} = time_slot, %User{} = user) do
    # Disallow reservations for past time slots
    if DateTime.compare(time_slot.start_time, DateTime.now!("Etc/UTC")) == :lt do
      {:error, :time_slot_is_in_the_past}
    else
      # First cancel any existing reservations for the same lab
      cancel_reservations(time_slot.tool_id, user)

      %Reservation{}
      |> Reservation.changeset(%{status: :reserved, user_id: user.id, time_slot_id: time_slot.id})
      |> Repo.insert()
    end
  end

  def reservation_for_user(%Tool{} = tool, %User{} = user) do
    reservation_query(tool.id, user)
    |> Repo.one()
  end

  def cancel_reservation(%Tool{} = tool, %User{} = user) do
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
    from(reservation in Reservation,
      join: time_slot in TimeSlot,
      on: [id: reservation.time_slot_id],
      join: tool in Tool,
      on: [id: time_slot.tool_id],
      where:
        reservation.user_id == ^user.id and tool.id == ^tool_id and
          reservation.status == :reserved
    )
  end
end
