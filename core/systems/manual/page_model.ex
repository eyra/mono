defmodule Systems.Manual.PageModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema
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

  def preload_graph(:userflow_step), do: [userflow_step: []]
end

defimpl Core.Persister, for: Systems.Manual.PageModel do
  def save(_page, changeset) do
    case Frameworks.Utility.EctoHelper.update_and_dispatch(changeset, :manual_page) do
      {:ok, %{manual_page: manual_page}} -> {:ok, manual_page}
      _ -> {:error, changeset}
    end
  end
end
