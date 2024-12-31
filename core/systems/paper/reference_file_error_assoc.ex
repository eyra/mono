defmodule Systems.Paper.ReferenceFileErrorAssoc do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  alias Systems.Paper

  schema "paper_reference_file_error" do
    field(:error, :string)
    belongs_to(:reference_file, Paper.ReferenceFileModel)
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
  def preload_graph(:up), do: preload_graph([:reference_file])
  def preload_graph(:reference_file), do: [reference_file: Paper.ReferenceFileModel.preload_graph(:up)]
end
