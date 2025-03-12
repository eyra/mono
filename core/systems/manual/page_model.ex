defmodule Systems.Manual.PageModel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "manual_page" do
    field(:image, :string)
    field(:title, :string)
    field(:text, :string)

    belongs_to(:chapter, Systems.Manual.ChapterModel)
    belongs_to(:userflow_step, Systems.Userflow.StepModel)

    timestamps()
  end

  @fields ~w(image title text)a
  @required_fields ~w()a

  def changeset(page, attrs \\ %{}) do
    page
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:down), do: [:userflow_step]
  def preload_graph(:up), do: []
end
