defmodule Systems.Affiliate.Model do
  use Ecto.Schema
  use Frameworks.Utility.Schema
  use Gettext, backend: MicaWeb.Gettext

  import Ecto.Changeset

  alias Frameworks.Utility.OutboundUrl

  schema "affiliate" do
    field(:callback_url, :string)
    field(:redirect_url, :string)
    field(:platform_name, :string)

    timestamps()
  end

  @fields ~w(callback_url redirect_url platform_name)a

  def changeset(affiliate, attrs) do
    affiliate
    |> cast(attrs, @fields)
    |> validate_change(:callback_url, &validate_url_change/2)
    |> validate_change(:redirect_url, &validate_url_change/2)
  end

  defp validate_url_change(field, url) do
    case validate_url(url) do
      {:ok, _url} -> []
      {:error, message} -> [{field, message}]
    end
  end

  def validate_url(nil), do: {:error, nil}
  def validate_url(""), do: {:error, nil}

  def validate_url(url) do
    case URI.new(url) do
      {:ok, %{scheme: nil}} -> {:error, dgettext("eyra-affiliate", "invalid_url.missing_scheme")}
      {:ok, %{scheme: ""}} -> {:error, dgettext("eyra-affiliate", "invalid_url.missing_scheme")}
      {:ok, %{host: nil}} -> {:error, dgettext("eyra-affiliate", "invalid_url.missing_host")}
      {:ok, %{host: ""}} -> {:error, dgettext("eyra-affiliate", "invalid_url.missing_host")}
      {:ok, _} -> validate_public_url(url)
      {:error, " "} -> {:error, dgettext("eyra-affiliate", "invalid_url.no_spaces_allowed")}
      {:error, _} -> {:error, dgettext("eyra-affiliate", "invalid_url.invalid_parts")}
    end
  end

  defp validate_public_url(url) do
    case OutboundUrl.check(url) do
      {:ok, _uri, _address} -> {:ok, url}
      {:error, reason} -> {:error, refusal(reason)}
    end
  end

  defp refusal(:scheme_not_allowed), do: dgettext("eyra-affiliate", "invalid_url.https_only")
  defp refusal(:port_not_allowed), do: dgettext("eyra-affiliate", "invalid_url.port_not_allowed")
  defp refusal(:invalid_url), do: dgettext("eyra-affiliate", "invalid_url.invalid_parts")

  # One answer for a name that doesn't resolve and one that resolves to a
  # private address, so the form can't tell which names the server's DNS knows.
  defp refusal(reason) when reason in [:host_not_found, :address_not_allowed, :timeout],
    do: dgettext("eyra-affiliate", "invalid_url.not_public")

  def preload_graph(:up), do: []
  def preload_graph(:down), do: []

  defimpl Mica.Persister do
    def save(_affiliate, changeset) do
      case Frameworks.Utility.EctoHelper.update_and_dispatch(changeset, :affiliate) do
        {:ok, %{affiliate: affiliate}} -> {:ok, affiliate}
        _ -> {:error, changeset}
      end
    end
  end
end
