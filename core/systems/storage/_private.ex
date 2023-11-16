defmodule Systems.Storage.Private do
  alias Systems.{
    Storage
  }

  def allowed_service_ids() do
    Keyword.get(config(), :services, [])
  end

  defp config() do
    Application.get_env(:core, :storage)
  end

  def build_special(:aws), do: %Storage.AWS.EndpointModel{}
  def build_special(:azure), do: %Storage.Azure.EndpointModel{}
  def build_special(:centerdata), do: %Storage.Centerdata.EndpointModel{}
  def build_special(:yoda), do: %Storage.Yoda.EndpointModel{}
end
