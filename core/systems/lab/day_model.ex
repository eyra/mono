defmodule Systems.Lab.DayModel do
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.{
    Lab
  }

  embedded_schema do
    field(:tool_id, :integer)
    field(:date, :date)
    field(:date_editable?, :boolean)
    field(:location, :string)
    field(:number_of_seats, :integer)
    field(:entries, {:array, :map})
  end

  @fields ~w(tool_id date location number_of_seats)a

  def changeset(model, :init, params) do
    model
    |> cast(params, @fields)
  end

  def changeset(model, :submit, params) do
    model
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> validate_unused_date()
  end

  defp validate_unused_date(changeset) do
    tool_id = get_field(changeset, :tool_id) |> IO.inspect(label: "TOOL_ID")
    date = get_field(changeset, :date) |> IO.inspect(label: "DATE")
    location = get_field(changeset, :location) |> IO.inspect(label: "LOCATION")

    time_slots =
      tool_id
      |> Lab.Context.get_time_slots()
      |> Enum.filter(& &1.location == location)
      |> Enum.filter(& CoreWeb.UI.Timestamp.to_date(&1.start_time) == date)
      |> IO.inspect(label: "TIMESLOTS LEFT")

    if Enum.empty?(time_slots) do
      changeset
    else
      %Ecto.Changeset{changeset |> add_error(:location, "lab location is already booked on the selected date") | action: :validate}
      |> IO.inspect(label: "CHSS")
    end
  end

end
