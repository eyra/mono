defmodule Systems.Manual.ChapterModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema
  import Ecto.Changeset

  alias Systems.Manual
  alias Systems.Userflow

  schema "manual_chapter" do
    field(:title, :string)

    belongs_to(:manual, Systems.Manual.Model)
    belongs_to(:userflow_step, Systems.Userflow.StepModel)
    belongs_to(:userflow, Systems.Userflow.Model)

    has_many(:pages, Systems.Manual.PageModel, foreign_key: :chapter_id)

    timestamps()
  end

  @fields ~w(title)a
  @required_fields ~w()a

  def changeset(chapter, attrs \\ %{}) do
    chapter
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:down), do: preload_graph([:userflow_step, :userflow, :pages])
  def preload_graph(:up), do: preload_graph([:manual])

  def preload_graph(:userflow_step), do: [userflow_step: Userflow.StepModel.preload_graph(:down)]
  def preload_graph(:userflow), do: [userflow: Userflow.Model.preload_graph(:down)]
  def preload_graph(:pages), do: [pages: Manual.PageModel.preload_graph(:down)]

  def preload_graph(:manual), do: [manual: Manual.Model.preload_graph(:up)]
end

defimpl Core.Persister, for: Systems.Manual.ChapterModel do
  def save(_chapter, changeset) do
    case Frameworks.Utility.EctoHelper.update_and_dispatch(changeset, :manual_chapter) do
      {:ok, %{manual_chapter: manual_chapter}} -> {:ok, manual_chapter}
      _ -> {:error, changeset}
    end
  end
end
