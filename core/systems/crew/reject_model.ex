defmodule Systems.Crew.RejectModel do
  use Ecto.Schema
  import Ecto.Changeset
  require Systems.Crew.RejectCategories

  embedded_schema do
    field(:category, Ecto.Enum, values: Systems.Crew.RejectCategories.schema_values())
    field(:message, :string)
  end

  @fields ~w(category message)a

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
