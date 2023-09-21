defmodule Systems.Feldspar.LocalFS do
  alias CoreWeb.Endpoint

  def store(zip_file) do
    id = Ecto.UUID.generate()
    path = get_path(id)
    File.mkdir!(path)
    :zip.unzip(to_charlist(zip_file), cwd: to_charlist(path))
    id
  end

  def storage_path(id) do
    get_path(id)
  end

  def get_public_url(id) do
    "#{Endpoint.url()}/#{static_path()}/#{id}"
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
    |> Application.get_env(:feldspar, [])
    |> Access.fetch!(:local_fs_root_path)
  end

  def static_path, do: "/feldspar_apps"
end
