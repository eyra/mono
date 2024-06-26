defmodule Systems.Storage.Public do
  require Logger

  alias Ecto.Changeset
  alias Core.Authorization
  alias Core.Repo
  alias Systems.Rate
  alias Systems.Storage

  def get_endpoint!(id, preload \\ []) do
    Repo.get!(Storage.EndpointModel, id)
    |> Repo.preload(preload)
  end

  def prepare_endpoint(special_type, attrs) do
    special_changeset = prepare_endpoint_special(special_type, attrs)

    %Storage.EndpointModel{}
    |> Storage.EndpointModel.change_special(special_type, special_changeset)
    |> Changeset.put_assoc(:auth_node, Authorization.prepare_node())
  end

  defp prepare_endpoint_special(:builtin, attrs) do
    %Storage.BuiltIn.EndpointModel{}
    |> Storage.BuiltIn.EndpointModel.changeset(attrs)
  end

  defp prepare_endpoint_special(:yoda, attrs) do
    %Storage.Yoda.EndpointModel{}
    |> Storage.Yoda.EndpointModel.changeset(attrs)
  end

  defp prepare_endpoint_special(:aws, attrs) do
    %Storage.AWS.EndpointModel{}
    |> Storage.AWS.EndpointModel.changeset(attrs)
  end

  defp prepare_endpoint_special(:azure, attrs) do
    %Storage.Azure.EndpointModel{}
    |> Storage.Azure.EndpointModel.changeset(attrs)
  end

  def store(
        %{key: key, backend: backend, endpoint: endpoint},
        data,
        %{remote_ip: remote_ip, panel_info: %{embedded?: embedded?}} = meta_data
      ) do
    packet_size = String.length(data)

    # raises error when request is denied
    Rate.Public.request_permission(key, remote_ip, packet_size)

    if embedded? do
      # submit data in current process
      Logger.warn("[Storage.Public] deliver directly")
      Storage.Delivery.deliver(backend, endpoint, data, meta_data)
    else
      %{
        backend: backend,
        endpoint: endpoint,
        data: data,
        meta_data: meta_data
      }
      |> Storage.Delivery.new()
      |> Oban.insert()
    end
  end

  def list_files(endpoint) do
    special = Storage.EndpointModel.special(endpoint)
    {_, backend} = Storage.Private.special_info(special)
    apply(backend, :list_files, [special])
  end

  def file_count(endpoint) do
    list_files(endpoint) |> Enum.count()
  end
end

defimpl Core.Persister, for: Systems.Storage.EndpointModel do
  def save(_endpoint, changeset) do
    case Frameworks.Utility.EctoHelper.update_and_dispatch(changeset, :storage_endpoint) do
      {:ok, %{storage_endpoint: storage_endpoint}} -> {:ok, storage_endpoint}
      _ -> {:error, changeset}
    end
  end
end
