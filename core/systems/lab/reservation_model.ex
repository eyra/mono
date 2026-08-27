defmodule Systems.Lab.ReservationModel do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Systems.Account.User
  alias Systems.Lab.TimeSlotModel

  @primary_key false
  schema "lab_reservations" do
    belongs_to(:time_slot, TimeSlotModel)
    belongs_to(:user, User)
    field(:status, Ecto.Enum, values: [:reserved, :completed, :cancelled, :missed])

    timestamps()
  end

  @doc false
  def changeset(lab_task, attrs) do
    lab_task
    |> cast(attrs, [:status, :time_slot_id, :user_id])
    |> validate_required([:status])
  end
end
