defmodule Systems.Storage.Private do
  alias Systems.{
    Storage
  }

  @centerdata_callback_url "https://quest.centerdata.nl/eyra/dd.php"

  def allowed_service_ids() do
    Keyword.get(config(), :services, [])
  end

  defp config() do
    Application.get_env(:core, :storage)
  end

  def build_special(:aws), do: %Storage.AWS.EndpointModel{}
  def build_special(:azure), do: %Storage.Azure.EndpointModel{}
  def build_special(:yoda), do: %Storage.Yoda.EndpointModel{}

  def backend_info(%Storage.AWS.EndpointModel{}), do: {:aws, Storage.AWS.Backend}
  def backend_info(%Storage.Azure.EndpointModel{}), do: {:azure, Storage.Azure.Backend}
  def backend_info(%Storage.Yoda.EndpointModel{}), do: {:yoda, Storage.Yoda.Backend}

  def storage_info(%{storage_endpoint: %{} = storage_endpoint, external_panel: external_panel}) do
    if endpoint = Storage.EndpointModel.special(storage_endpoint) do
      {key, backend} = backend_info(endpoint)
      %{key: key, backend: backend, endpoint: endpoint}
    else
      storage_info(external_panel)
    end
  end

  def storage_info(%{external_panel: external_panel}) do
    storage_info(external_panel)
  end

  def storage_info(:liss) do
    endpoint = %Storage.Centerdata.EndpointModel{url: @centerdata_callback_url}
    backend = Storage.Centerdata.Backend
    %{key: :centerdata, endpoint: endpoint, backend: backend}
  end

  def storage_info(_), do: nil
end
