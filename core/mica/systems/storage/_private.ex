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

  @doc """
  Returns the node-local Oban queue name for storage operations.

  Data donation files are stored on the local filesystem, so storage delivery
  jobs must be processed by the same node that received the donation.
  The queue name is derived from Node.self() to ensure jobs are processed
  only by the node that has access to the local filesystem.

  Uses the same naming scheme as runtime.exs configuration.
  """
  def storage_delivery_queue do
    :"storage_delivery_local_#{Node.self()}"
  end
end
