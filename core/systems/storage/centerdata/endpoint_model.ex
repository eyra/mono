defmodule Systems.Storage.Centerdata.EndpointModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  @fields ~w(url)a
  @required_fields @fields

  @derive {Jason.Encoder, only: @fields}
  schema "storage_endpoints_centerdata" do
    field(:url, :string)

    timestamps()
  end

  def changeset(model, params) do
    model
    |> cast(params, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def ready?(tool) do
    changeset =
      changeset(tool, %{})
      |> validate()

    changeset.valid?
  end

  def connected?(_endpoint) do
    {:ok, true}
  end

  def preload_graph(:down), do: []

  defimpl Frameworks.Concept.ContentModel do
    alias Systems.Storage.Centerdata
    def form(_), do: Centerdata.EndpointForm
    def ready?(endpoint), do: Centerdata.EndpointModel.ready?(endpoint)
  end
end
