defmodule Systems.Sequence.ElementModel do
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.{
    Sequence
  }

  schema "sequence_elements" do
    belongs_to(:sequence, Sequence.Model)
    field(:position, :integer)
    field(:director, Ecto.Enum, values: [:study])
    field(:identifier, {:array, :string})
    timestamps()
  end

  @required_fields ~w(position director identifier)a
  @fields @required_fields

  @doc false
  def changeset(element, attrs) do
    element
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  def preload_graph(_), do: []
end
