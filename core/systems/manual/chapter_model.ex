defmodule Systems.Manual.ChapterModel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "manual_chapter" do
    field(:title, :string)
    field(:description, :string)

    belongs_to(:manual, Systems.Manual.Model)
    belongs_to(:userflow_step, Systems.Userflow.StepModel)
    belongs_to(:userflow, Systems.Userflow.Model)

    has_many(:pages, Systems.Manual.PageModel, foreign_key: :chapter_id)

    timestamps()
  end

  @fields ~w(title description)a
  @required_fields ~w()a

  def changeset(chapter, attrs \\ %{}) do
    chapter
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:down), do: [:userflow_step, :userflow]
  def preload_graph(:up), do: [:manual]
end
