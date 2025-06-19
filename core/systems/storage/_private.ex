defmodule Systems.Storage.Private do
  alias Systems.Storage

  def allowed_service_ids() do
    Keyword.get(config(), :services, [])
  end

  defp config() do
    Application.get_env(:core, :storage)
  end

  def build_special(:builtin), do: %Storage.BuiltIn.EndpointModel{}
  def build_special(:yoda), do: %Storage.Yoda.EndpointModel{}
  def build_special(:aws), do: %Storage.AWS.EndpointModel{}
  def build_special(:azure), do: %Storage.Azure.EndpointModel{}

  def special_info(%Storage.EndpointModel{} = endpoint) do
    endpoint
    |> Storage.EndpointModel.special()
    |> special_info()
  end

  def special_info(%Storage.BuiltIn.EndpointModel{}), do: {:builtin, Storage.BuiltIn.Backend}
  def special_info(%Storage.Yoda.EndpointModel{}), do: {:yoda, Storage.Yoda.Backend}
  def special_info(%Storage.AWS.EndpointModel{}), do: {:aws, Storage.AWS.Backend}
  def special_info(%Storage.Azure.EndpointModel{}), do: {:azure, Storage.Azure.Backend}

  def storage_info(storage_endpoint) do
    special = Storage.EndpointModel.special(storage_endpoint)
    {key, backend} = special_info(special)
    %{key: key, special: special, backend: backend}
  end
end
