defmodule Systems.Manual.Model do
  use Ecto.Schema
  use Frameworks.Utility.Schema
  import Ecto.Changeset

  alias Systems.Manual
  alias Systems.Userflow

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

  def preload_graph(:down), do: preload_graph([:userflow, :chapters])
  def preload_graph(:up), do: []

  def preload_graph(:userflow), do: [userflow: Userflow.Model.preload_graph(:down)]
  def preload_graph(:chapters), do: [chapters: Manual.ChapterModel.preload_graph(:down)]
end
