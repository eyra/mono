defmodule Systems.Version.Model do
  use Ecto.Schema
  use Frameworks.Utility.Schema
  import Ecto.Changeset

  alias Systems.Version

  schema "version" do
    field(:number, :integer)

    belongs_to(:parent, __MODULE__)
    has_one(:child, __MODULE__, foreign_key: :parent_id)

    timestamps()
  end

  @fields [:number]
  @required_fields @fields

  def changeset(version, attrs) do
    version
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
    |> validate_number(:number, greater_than: 0)
  end

  def prepare_first() do
    %__MODULE__{}
    |> cast(%{number: 1}, @fields)
    |> validate()
  end

  def prepare_new(%__MODULE__{number: parent_number} = parent) do
    %__MODULE__{}
    |> cast(%{number: parent_number + 1}, @fields)
    |> put_assoc(:parent, parent)
    |> validate()
  end

  def preload_graph(:up), do: preload_graph([:parent])
  def preload_graph(:down), do: preload_graph([:child])

  def preload_graph(:parent), do: [parent: Version.Model.preload_graph(:up)]
  def preload_graph(:child), do: [child: Version.Model.preload_graph(:down)]
end
