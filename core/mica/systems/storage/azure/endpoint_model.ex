defmodule Systems.Storage.Azure.EndpointModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema
  use Gettext, backend: MicaWeb.Gettext

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
    model
    |> cast(params, @fields)
    |> validate_change(:account_name, fn field, account_name ->
      if valid_account_name?(account_name),
        do: [],
        else: [{field, dgettext("eyra-storage", "azure.account_name.invalid")}]
    end)
  end

  @doc """
  True for a name of letters and digits only. The account name is the first
  label of the host `<account_name>.blob.core.windows.net`, so any other
  character could make the host something else.
  """
  def valid_account_name?(account_name) when is_binary(account_name),
    do: String.match?(account_name, ~r/\A[a-z0-9]+\z/i)

  def valid_account_name?(_), do: false

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
    {:ok, false}
  end

  def preload_graph(:down), do: []

  defimpl Frameworks.Concept.ContentModel do
    alias Systems.Storage.Azure
    def form(_), do: Azure.EndpointForm
    def ready?(endpoint), do: Azure.EndpointModel.ready?(endpoint)
  end
end
