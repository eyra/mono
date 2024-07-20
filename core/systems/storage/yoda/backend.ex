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
        meta_data
      ) do
    filename = filename(meta_data)
    file_url = url([yoda_url, filename])

    {:ok, _} = Yoda.Client.upload_file(username, password, file_url, data)
  end

  def list_files(_endpoint) do
    Logger.error("Not yet implemented: list_files/1")
    {:error, :not_implemented}
  end

  def delete_files(_endpoint) do
    Logger.error("Not yet implemented: delete_files/1")
    {:error, :not_implemented}
  end

  def connected?(%{user: user, password: _, url: _}) when user == nil or user == "", do: false

  def connected?(%{user: _, password: password, url: _}) when password == nil or password == "",
    do: false

  def connected?(%{user: _, password: _, url: url}) when url == nil or url == "", do: false

  def connected?(%{user: user, password: password, url: url}) do
    cond do
      is_nil(user) or user == "" ->
        false

      is_nil(password) or password == "" ->
        false

      is_nil(url) or url == "" ->
        false

      true ->
        case Yoda.Client.connected?(user, password, url) do
          {:ok, connected?} -> connected?
          {:error, _} -> false
        end
    end
  end

  def connected?(_), do: false

  defp filename(%{"identifier" => identifier}) do
    identifier
    |> Enum.map_join("_", fn [key, value] -> "#{key}-#{value}" end)
    |> then(&"#{&1}.json")
  end

  defp url(components) do
    Enum.join(components, "/")
  end
end
