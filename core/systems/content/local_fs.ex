defmodule Systems.Content.LocalFS do
  alias CoreWeb.Endpoint

  def store(tmp_path) do
    uuid = Ecto.UUID.generate()
    extname = Path.extname(tmp_path)
    id = "#{uuid}#{extname}"
    path = get_path(id)
    File.cp!(tmp_path, path)
    id
  end

  def storage_path(id) do
    get_path(id)
  end

  def get_public_url(id) do
    "#{Endpoint.url()}/#{public_path()}/#{id}"
  end

  def remove(id) do
    with {:ok, _} <- File.rm_rf(get_path(id)) do
      :ok
    end
  end

  defp get_path(id) do
    Path.join(get_root_path(), id)
  end

  def get_root_path do
    :core
    |> Application.get_env(:content, [])
    |> Access.fetch!(:local_fs_root_path)
  end

  def public_path, do: "/content"
end
