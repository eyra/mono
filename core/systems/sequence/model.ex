defmodule Systems.Sequence.Model do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.{
    Sequence
  }

  schema "sequences" do
    has_many(:elements, Sequence.ElementModel, foreign_key: :sequence_id)
    timestamps()
  end

  @required_fields ~w()a
  @fields @required_fields

  @doc false
  def changeset(sequence, attrs) do
    sequence
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  def preload_graph(:full),
    do:
      preload_graph([
        :elements
      ])

  def preload_graph(:elements), do: [elements: [:lab_tool, :survey_tool, :data_donation_tool]]
end
