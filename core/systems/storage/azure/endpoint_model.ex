defmodule Systems.Storage.Azure.EndpointModel do
  @moduledoc false
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  @fields ~w(account_name container sas_token)a
  @required_fields @fields

  @derive {Jason.Encoder, only: @fields}
  @derive {Inspect, except: [:sas_token]}
  schema "storage_endpoints_azure" do
    field(:account_name, :string)
    field(:container, :string)
    field(:sas_token, :string)

    timestamps()
  end

  def changeset(model, params) do
    cast(model, params, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def ready?(tool) do
    changeset =
      tool
      |> changeset(%{})
      |> validate()

    changeset.valid?
  end

  def connected?(_endpoint) do
    {:ok, false}
  end

  def preload_graph(:down), do: []

  defimpl Frameworks.Concept.ContentModel do
    alias Systems.Storage.Azure

    def form(_), do: Azure.EndpointForm
    def ready?(endpoint), do: Azure.EndpointModel.ready?(endpoint)
  end
end
