defmodule Systems.Storage.BuiltIn.EndpointModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  @fields ~w(key)a
  @required_fields @fields

  @derive {Jason.Encoder, only: @fields}
  schema "storage_endpoints_builtin" do
    field(:key, :string)
    timestamps()
  end

  def changeset(endpoint, params) do
    endpoint |> cast(params, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
    |> unique_constraint(:key)
  end

  def ready?(endpoint) do
    changeset =
      endpoint
      |> changeset(%{})
      |> validate()

    changeset.valid?()
  end

  def preload_graph(:down), do: []

  defimpl Frameworks.Concept.ContentModel do
    alias Systems.Storage.BuiltIn
    def form(_), do: BuiltIn.EndpointForm
    def ready?(endpoint), do: BuiltIn.EndpointModel.ready?(endpoint)
  end
end
