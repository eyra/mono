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
    zip = to_charlist(zip_file)
    ensure_entries_inside!(zip, path)
    File.mkdir!(path)
    :zip.unzip(zip, cwd: to_charlist(path))
    folder
  end

  defp ensure_entries_inside!(zip, path) do
    {:ok, entries} = :zip.list_dir(zip)

    outside =
      for {:zip_file, name, _info, _comment, _offset, _size} <- entries,
          not inside?(to_string(name), path),
          do: to_string(name)

    if outside != [] do
      raise ArgumentError, "Zip entries outside the app folder: #{Enum.join(outside, ", ")}"
    end
  end

  defp inside?(name, path) do
    root = Path.expand(path)
    expanded = Path.expand(name, root)
    expanded == root or String.starts_with?(expanded, root <> "/")
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
    Core.Env.get(:upload_path)
  end
end
