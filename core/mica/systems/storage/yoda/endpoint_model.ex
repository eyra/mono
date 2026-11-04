defmodule Systems.Storage.Yoda.EndpointModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema
  use Gettext, backend: MicaWeb.Gettext

  import Ecto.Changeset
  alias Frameworks.Utility.OutboundUrl
  alias Systems.Storage.Yoda

  @fields ~w(url user password)a
  @required_fields @fields

  @derive {Jason.Encoder, only: @fields}
  @derive {Inspect, except: [:user, :password]}
  schema "storage_endpoints_yoda" do
    field(:url, :string)
    field(:user, :string)
    field(:password, :string)

    timestamps()
  end

  def changeset(endpoint, params) do
    endpoint
    |> cast(params, @fields)
    |> validate_change(:url, &validate_url/2)
  end

  defp validate_url(field, url) do
    case OutboundUrl.check(url) do
      {:ok, _uri, _address} -> []
      {:error, reason} -> [{field, refusal(reason)}]
    end
  end

  defp refusal(:scheme_not_allowed), do: dgettext("eyra-storage", "url.https_only")
  defp refusal(:port_not_allowed), do: dgettext("eyra-storage", "url.port_not_allowed")
  defp refusal(:invalid_url), do: dgettext("eyra-storage", "url.invalid")

  # One answer for a name that doesn't resolve and one that resolves to a
  # private address, so the form can't tell which names the server's DNS knows.
  defp refusal(reason) when reason in [:host_not_found, :address_not_allowed, :timeout],
    do: dgettext("eyra-storage", "url.not_public")

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def ready?(endpoint) do
    changeset =
      changeset(endpoint, %{})
      |> validate()

    changeset.valid?
  end

  def preload_graph(:down), do: []

  defimpl Frameworks.Concept.ContentModel do
    alias Systems.Storage.Yoda
    def form(_), do: Yoda.EndpointForm
    def ready?(endpoint), do: Yoda.EndpointModel.ready?(endpoint)
  end
end
