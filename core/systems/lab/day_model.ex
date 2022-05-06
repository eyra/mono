defmodule Systems.Lab.DayModel do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:action, Ecto.Enum, values: [:new, :duplicate, :edit])
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
  end
end
