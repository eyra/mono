defmodule Systems.Storage.Yoda.EndpointModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  @fields ~w(url user password)a
  @required_fields @fields

  @derive {Jason.Encoder, only: @fields}
  schema "storage_endpoints_yoda" do
    field(:url, :string)
    field(:user, :string)
    field(:password, :string)

    timestamps()
  end

  def changeset(endpoint, params) do
    endpoint
    |> cast(params, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def ready?(endpoint) do
    changeset =
      changeset(endpoint, %{})
      |> validate()

    changeset.valid?()
  end

  def preload_graph(:down), do: []

  defimpl Frameworks.Concept.ContentModel do
    alias Systems.Storage.Yoda
    def form(_), do: Yoda.EndpointForm
    def ready?(endpoint), do: Yoda.EndpointModel.ready?(endpoint)
  end
end
