defmodule Systems.Monitor.EventModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  schema "monitor_events" do
    field(:identifier, {:array, :string})
    field(:value, :integer)

    timestamps()
  end

  @fields ~w(identifier value)a
  @required_fields @fields

  def changeset(model, params) do
    cast(model, params, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end
end
