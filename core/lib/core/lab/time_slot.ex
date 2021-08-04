defmodule Core.Lab.TimeSlot do
  use Ecto.Schema
  import Ecto.Changeset
  alias Core.Lab.Tool
  alias Core.Lab.Reservation

  schema "lab_time_slots" do
    belongs_to(:tool, Tool)

    field(:location, :string)
    field(:start_time, :utc_datetime)
    field(:number_of_seats, :integer)

    has_many(:reservations, Reservation)

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
