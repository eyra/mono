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
        %{
          "participant" => participant
        } = _panel_info,
        data,
        %{
          "key" => key
        } = _meta_data
      ) do
    folder = "participant-#{participant}"
    folder_url = url([yoda_url, folder])

    file = "#{key}.json"
    file_url = url([yoda_url, folder, file])

    with {:ok, false} <- Yoda.Client.has_resource?(username, password, folder_url) do
      {:ok, _} = Yoda.Client.create_folder(username, password, folder_url)
    end

    {:ok, _} = Yoda.Client.upload_file(username, password, file_url, data)
  end

  defp url(components) do
    Enum.join(components, "/")
  end
end
