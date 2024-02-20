defmodule Systems.Storage.BuiltIn.Backend do
  @behaviour Systems.Storage.Backend

  alias CoreWeb.UI.Timestamp
  alias Systems.Storage.BuiltIn

  def store(%{"key" => folder}, panel_info, data, meta_data) do
    identifier = identifier(panel_info, meta_data)
    special().store(folder, identifier, data)
  end

  def store(_, _, _, _) do
    {:error, :endpoint_key_missing}
  end

  defp identifier(%{"participant" => participant}, %{"key" => meta_key, "group" => group})
       when not is_nil(group) do
    ["participant=#{participant}", "source=#{group}", meta_key]
  end

  defp identifier(%{"participant" => participant}, %{"key" => meta_key}) do
    ["participant=#{participant}", meta_key]
  end

  defp identifier(%{"participant" => participant}, _) do
    timestamp = Timestamp.now() |> DateTime.to_unix()
    ["participant=#{participant}", "#{timestamp}"]
  end

  defp identifier(_, _) do
    timestamp = Timestamp.now() |> DateTime.to_unix()
    ["participant=?", "#{timestamp}"]
  end

  defp settings do
    Application.fetch_env!(:core, Systems.Storage.BuiltIn)
  end

  defp special do
    # Allow mocking
    Access.get(settings(), :special, BuiltIn.LocalFS)
  end
end
