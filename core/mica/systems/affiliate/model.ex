defmodule Systems.Affiliate.Model do
  use Ecto.Schema
  use Frameworks.Utility.Schema
  use Gettext, backend: CoreWeb.Gettext

  import Ecto.Changeset

  schema "affiliate" do
    field(:callback_url, :string)
    field(:redirect_url, :string)
    field(:platform_name, :string)

    timestamps()
  end

  @fields ~w(callback_url redirect_url platform_name)a

  def changeset(affiliate, attrs) do
    cast(affiliate, attrs, @fields)
  end

  def validate_url(nil), do: {:error, nil}
  def validate_url(""), do: {:error, nil}

  def validate_url(url) do
    case URI.new(url) do
      {:ok, %{scheme: nil}} -> {:error, dgettext("eyra-affiliate", "invalid_url.missing_scheme")}
      {:ok, %{scheme: ""}} -> {:error, dgettext("eyra-affiliate", "invalid_url.missing_scheme")}
      {:ok, %{host: nil}} -> {:error, dgettext("eyra-affiliate", "invalid_url.missing_host")}
      {:ok, %{host: ""}} -> {:error, dgettext("eyra-affiliate", "invalid_url.missing_host")}
      {:ok, _} -> {:ok, url}
      {:error, " "} -> {:error, dgettext("eyra-affiliate", "invalid_url.no_spaces_allowed")}
      {:error, _} -> {:error, dgettext("eyra-affiliate", "invalid_url.invalid_parts")}
    end
  end

  def preload_graph(:up), do: []
  def preload_graph(:down), do: []

  defimpl Core.Persister do
    def save(_affiliate, changeset) do
      case Frameworks.Utility.EctoHelper.update_and_dispatch(changeset, :affiliate) do
        {:ok, %{affiliate: affiliate}} -> {:ok, affiliate}
        _ -> {:error, changeset}
      end
    end
  end
end
