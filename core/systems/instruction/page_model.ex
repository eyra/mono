defmodule Systems.Instruction.PageModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Instruction
  alias Systems.Content

  schema "instruction_pages" do
    belongs_to(:tool, Instruction.ToolModel)
    belongs_to(:page, Content.PageModel)

    timestamps()
  end

  @fields ~w()a
  @required_fields @fields

  def changeset(page, attrs \\ %{}) do
    cast(page, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: preload_graph([:page])
  def preload_graph(:page), do: [page: Content.PageModel.preload_graph(:down)]
end
