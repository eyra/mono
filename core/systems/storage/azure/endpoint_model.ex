defmodule Systems.Storage.Azure.EndpointModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  schema "storage_endpoints_azure" do
    field(:account_name, :string)
    field(:container, :string)
    field(:sas_token, :string)

    timestamps()
  end

  @fields ~w(account_name container sas_token)a
  @required_fields @fields

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

    changeset.valid?()
  end

  def preload_graph(:down), do: []

  defimpl Frameworks.Concept.ContentModel do
    alias Systems.Storage.Azure
    def form(_), do: Azure.EndpointForm
    def ready?(endpoint), do: Azure.EndpointModel.ready?(endpoint)
  end
end
