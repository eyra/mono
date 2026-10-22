defmodule Systems.Instruction.AssetModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Instruction
  alias Systems.Content

  schema "instruction_assets" do
    belongs_to(:tool, Instruction.ToolModel)
    belongs_to(:repository, Content.RepositoryModel)
    belongs_to(:file, Content.FileModel)

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

  def preload_graph(:down), do: preload_graph([:repository, :file])
  def preload_graph(:repository), do: [repository: Content.RepositoryModel.preload_graph(:down)]
  def preload_graph(:file), do: [file: Content.FileModel.preload_graph(:down)]
end
