defmodule Systems.Storage.AWS.EndpointModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  @fields ~w(access_key_id secret_access_key s3_bucket_name region_code)a
  @required_fields @fields

  @derive {Jason.Encoder, only: @fields}
  @derive {Inspect, except: [:secret_access_key]}
  schema "storage_endpoints_aws" do
    field(:access_key_id, :string)
    field(:secret_access_key, :string)
    field(:s3_bucket_name, :string)
    field(:region_code, :string)

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

    changeset.valid?()
  end

  def connected?(_endpoint) do
    {:ok, false}
  end

  def preload_graph(:down), do: []

  defimpl Frameworks.Concept.ContentModel do
    alias Systems.Storage.AWS
    def form(_), do: AWS.EndpointForm
    def ready?(endpoint), do: AWS.EndpointModel.ready?(endpoint)
  end
end
