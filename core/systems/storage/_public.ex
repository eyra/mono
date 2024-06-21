defmodule Systems.Storage.Public do
  require Logger

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
    |> Storage.EndpointModel.reset_special(special_type, special_changeset)
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
        %{embedded?: embedded?} = panel_info,
        data,
        %{remote_ip: remote_ip} = meta_data
      ) do
    packet_size = String.length(data)

    # raises error when request is denied
    Rate.Public.request_permission(key, remote_ip, packet_size)

    if embedded? do
      # submit data in current process
      Logger.warn("[Storage.Public] deliver directly")
      Storage.Delivery.deliver(backend, endpoint, panel_info, data, meta_data)
    else
      %{
        backend: backend,
        endpoint: endpoint,
        panel_info: panel_info,
        data: data,
        meta_data: meta_data
      }
      |> Storage.Delivery.new()
      |> Oban.insert()
    end
  end

  def file_count(%Storage.EndpointModel{}) do
    0
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
