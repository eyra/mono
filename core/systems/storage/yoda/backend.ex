defmodule Systems.Storage.Yoda.Backend do
  @behaviour Systems.Storage.Backend

  alias Systems.Storage.Yoda

  require Logger

  def store(
        %{
          "user" => username,
          "password" => password,
          "url" => yoda_url
        } = _endpoint,
        data,
        %{
          identifier: identifier
        } = _meta_data
      ) do
    filename = filename(identifier)
    file_url = url([yoda_url, filename])

    {:ok, _} = Yoda.Client.upload_file(username, password, file_url, data)
  end

  def list_files(_endpoint) do
    Logger.error("Not yet implemented: files/4")
    {:error, :not_implemented}
  end

  defp filename(%{"identifier" => identifier}) do
    identifier
    |> Enum.map_join("_", fn [key, value] -> "#{key}-#{value}" end)
    |> then(&"#{&1}.json")
  end

  defp url(components) do
    Enum.join(components, "/")
  end
end
