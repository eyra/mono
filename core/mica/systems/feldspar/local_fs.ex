defmodule Systems.Feldspar.LocalFS do
  use CoreWeb, :verified_routes

  def public_path, do: "/feldspar/apps"

  def get_public_url(id) do
    ~p"/feldspar/apps/#{id}"
  end

  def store(zip_file, original_filename) do
    uuid = Ecto.UUID.generate()
    base_folder = Path.basename(original_filename, ".zip")
    folder = "#{uuid}_#{base_folder}"
    path = get_path(folder)
    File.mkdir!(path)
    :zip.unzip(to_charlist(zip_file), cwd: to_charlist(path))
    folder
  end

  def storage_path(folder) do
    get_path(folder)
  end

  def remove(folder) do
    with {:ok, _} <- File.rm_rf(get_path(folder)) do
      :ok
    end
  end

  defp get_path(folder) do
    Path.join(get_root_path(), folder)
  end

  def get_root_path do
    Application.get_env(:core, :upload_path)
  end
end
