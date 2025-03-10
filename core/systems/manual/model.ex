defmodule Systems.Manual.Model do
  use Ecto.Schema
  import Ecto.Changeset

  schema "manuals" do
    field(:identifier, :string)
    field(:title, :string)
    field(:description, :string)

    has_many(:chapters, Systems.Manual.ChapterModel, foreign_key: :manual_id)
    belongs_to(:userflow, Systems.Userflow.Model)

    timestamps()
  end

  @fields ~w(identifier title description)a
  @required_fields ~w(identifier title)a

  def changeset(manual, attrs \\ %{}) do
    manual
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
    |> validate_length(:title, min: 2, max: 255)
    |> validate_length(:identifier, min: 2, max: 100)
    |> unique_constraint(:identifier)
  end

  def preload_graph(:down),
    do: [chapters: [userflow: Systems.Userflow.Model.preload_graph(:down)]]

  def preload_graph(:up), do: [:userflow]
end
