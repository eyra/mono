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
    tool_id = get_field(changeset, :tool_id)
    date = get_field(changeset, :date)
    location = get_field(changeset, :location)

    time_slots =
      tool_id
      |> Lab.Context.get_time_slots()
      |> Enum.filter(
        &(&1.location == location and CoreWeb.UI.Timestamp.to_date(&1.start_time) == date)
      )

    if Enum.empty?(time_slots) do
      changeset
    else
      %Ecto.Changeset{
        (changeset
         |> add_error(:location, "lab location is already booked on the selected date"))
        | action: :validate
      }
    end
  end
end
