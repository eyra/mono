defmodule Systems.Lab.TimeSlotModel do
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.{
    Lab
  }

  schema "lab_time_slots" do
    belongs_to(:tool, Lab.ToolModel)

    field(:location, :string)
    field(:start_time, :utc_datetime)
    field(:number_of_seats, :integer)

    has_many(:reservations, Lab.ReservationModel, foreign_key: :time_slot_id)

    timestamps()
  end

  @doc false
  def changeset(participant) do
    participant
    |> cast(%{}, [])
    |> validate_number(:number_of_seats, greater_than_or_equal_to: 1)

    # FIXME: Validate number_of_seats greater than or equal to
    # reservervation count
  end
end
