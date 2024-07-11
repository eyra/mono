defmodule Systems.Storage.Private do
  alias Systems.Storage

  @centerdata_callback_url "https://quest.centerdata.nl/eyra/dd.php"

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

  @spec storage_info(any()) ::
          {:error, {:storage_info, :not_available}}
          | %{
              backend:
                Systems.Storage.AWS.Backend
                | Systems.Storage.Azure.Backend
                | Systems.Storage.BuiltIn.Backend
                | Systems.Storage.Centerdata.Backend
                | Systems.Storage.Yoda.Backend,
              endpoint: %{
                :__struct__ =>
                  Systems.Storage.AWS.EndpointModel
                  | Systems.Storage.Azure.EndpointModel
                  | Systems.Storage.BuiltIn.EndpointModel
                  | Systems.Storage.Centerdata.EndpointModel
                  | Systems.Storage.Yoda.EndpointModel,
                optional(any()) => any()
              },
              key: :aws | :azure | :builtin | :centerdata | :yoda
            }
  def storage_info(storage_endpoint, %{external_panel: external_panel}) do
    if special = Storage.EndpointModel.special(storage_endpoint) do
      {key, backend} = special_info(special)
      {:ok, %{key: key, special: special, backend: backend}}
    else
      storage_info(external_panel)
    end
  end

  def storage_info(:liss) do
    special = %Storage.Centerdata.EndpointModel{url: @centerdata_callback_url}
    backend = Storage.Centerdata.Backend
    {:ok, %{key: :centerdata, special: special, backend: backend}}
  end

  def storage_info(_), do: {:error, {:storage_info, :not_available}}
end
