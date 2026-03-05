defmodule Systems.Crew.RejectModel do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Systems.Crew.RejectCategories

  require RejectCategories

  embedded_schema do
    field(:category, Ecto.Enum, values: RejectCategories.schema_values())
    field(:message, :string)
  end

  @fields ~w(category message)a

  def changeset(model, :init, params) do
    cast(model, params, @fields)
  end

  def changeset(model, :submit, params) do
    model
    |> cast(params, @fields)
    |> validate_required(@fields)
  end
end
