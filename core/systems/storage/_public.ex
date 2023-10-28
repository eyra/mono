defmodule Systems.Storage.Public do
  alias Systems.{
    Storage
  }

  def deliver(%Storage.EndpointModel{} = _endpoint, data) when is_binary(data) do
    %{endpoint: %{type: :aws}, data: data}
    |> Storage.Delivery.new()
    |> Oban.insert()
  end
end
