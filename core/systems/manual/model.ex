defmodule Systems.Manual.Model do
  use Ecto.Schema
  import Ecto.Changeset

  schema "manual" do
    field(:title, :string)
    field(:description, :string)

    # Each manual has a userflow for its chapters
    belongs_to(:userflow, Systems.Userflow.Model)

    has_many(:chapters, Systems.Manual.ChapterModel, foreign_key: :manual_id)
    timestamps()
  end

  @fields ~w(title description)a
  @required_fields ~w()a

  def changeset(manual, attrs \\ %{}) do
    manual
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:down), do: [:userflow]
  def preload_graph(:up), do: []
end
