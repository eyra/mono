defmodule Systems.Manual.ChapterModel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "manual_chapters" do
    field(:identifier, :string)
    field(:title, :string)
    field(:description, :string)
    field(:order, :integer)

    belongs_to(:manual, Systems.Manual.Model)
    belongs_to(:userflow, Systems.Userflow.Model)

    timestamps()
  end

  @fields ~w(identifier title description order)a
  @required_fields ~w(identifier title order)a

  def changeset(chapter, attrs \\ %{}) do
    chapter
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
    |> validate_length(:title, min: 2, max: 255)
    |> validate_length(:identifier, min: 2, max: 100)
    |> validate_number(:order, greater_than: 0)
    |> unique_constraint([:identifier, :manual_id])
    |> unique_constraint([:order, :manual_id])
    |> foreign_key_constraint(:manual_id)
    |> foreign_key_constraint(:userflow_id)
  end

  def preload_graph(:down), do: [userflow: Systems.Userflow.Model.preload_graph(:down)]
  def preload_graph(:up), do: [:manual]
end
