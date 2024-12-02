defmodule Systems.Onyx.FileErrorAssociation do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  alias Systems.Onyx

  schema "onyx_file_error" do
    field(:error, :string)
    belongs_to(:tool_file, Onyx.ToolFileAssociation)
    timestamps()
  end

  @fields ~w(error)a
  @required_fields @fields

  def changeset(file_error, attrs) do
    cast(file_error, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: preload_graph([])
  def preload_graph(:up), do: preload_graph([:tool_file])
  def preload_graph(:tool_file), do: [tool_file: Onyx.ToolFileAssociation.preload_graph(:up)]
end
