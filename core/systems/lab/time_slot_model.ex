defmodule Systems.Lab.TimeSlotModel do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias CoreWeb.UI.Timestamp
  alias Systems.Lab

  schema "lab_time_slots" do
    belongs_to(:tool, Lab.ToolModel)

    field(:enabled?, :boolean)
    field(:location, :string)
    field(:start_time, :utc_datetime)
    field(:number_of_seats, :integer)

    has_many(:reservations, Lab.ReservationModel, foreign_key: :time_slot_id)

    timestamps()
  end

  @doc false
  def changeset(time_slot, attrs \\ %{}) do
    cast(time_slot, attrs, [:enabled?, :location, :start_time, :number_of_seats])
  end

  def message(%{start_time: start_time, location: location}) do
    date =
      start_time
      |> Timestamp.to_date()
      |> Timestamp.humanize_date()

    time = Timestamp.humanize_time(start_time)

    Macro.camelize(" #{date}  |  #{time}  |  #{location}")
  end

  def count_reservations(timeslot, included) do
    timeslot
    |> filter_reservations(included)
    |> Enum.count()
  end

  def filter_reservations(%{reservations: reservations}, included) when is_list(included) do
    Enum.filter(reservations, &Enum.member?(included, &1.status))
  end

  def filter_reservations(%{reservations: reservations}, included) when is_atom(included) do
    Enum.filter(reservations, &(&1.status == included))
  end
end
