defmodule Systems.Storage.Public do
  require Logger

  alias Systems.{
    Rate,
    Storage
  }

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
end

defimpl Core.Persister, for: Systems.Storage.EndpointModel do
  def save(_endpoint, changeset) do
    case Frameworks.Utility.EctoHelper.update_and_dispatch(changeset, :storage_endpoint) do
      {:ok, %{storage_endpoint: storage_endpoint}} -> {:ok, storage_endpoint}
      _ -> {:error, changeset}
    end
  end
end
