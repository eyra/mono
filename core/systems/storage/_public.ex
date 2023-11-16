defmodule Systems.Storage.Public do
  alias Systems.{
    Rate,
    Storage
  }

  def store(%Storage.EndpointModel{} = endpoint, data, remote_ip) do
    storage = %{
      key: Storage.EndpointModel.special_field_id(endpoint),
      endpoint: Storage.EndpointModel.special(endpoint)
    }

    packet_size = String.length(data)

    with :granted <- Rate.Public.request_permission(storage.key, remote_ip, packet_size) do
      %{
        storage: storage,
        data: data
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
