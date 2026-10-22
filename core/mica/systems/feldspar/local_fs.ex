defmodule Systems.Feldspar.LocalFS do
  use CoreWeb, :verified_routes

  def public_path, do: "/feldspar/apps"

  def get_public_url(id) do
    ~p"/feldspar/apps/#{id}"
  end

  @local_file_header 0x04034B50

  @doc """
  Extracts the zip into a new app folder and returns the folder name, or
  `{:error, :invalid_zip}` when the file is no zip or has an entry that would
  be written outside the app folder.
  """
  def store(zip_file, original_filename) do
    uuid = Ecto.UUID.generate()
    base_folder = Path.basename(original_filename, ".zip")
    folder = "#{uuid}_#{base_folder}"
    path = get_path(folder)

    if valid_zip?(zip_file, path) do
      File.mkdir!(path)
      {:ok, _} = :zip.unzip(to_charlist(zip_file), cwd: to_charlist(path))
      folder
    else
      {:error, :invalid_zip}
    end
  end

  # :zip.list_dir returns the names in the central directory, but :zip.unzip
  # writes each entry under the name in its local file header. Both must agree
  # and resolve inside the app folder.
  defp valid_zip?(zip_file, path) do
    root = Path.expand(path)

    with {:ok, entries} <- :zip.list_dir(to_charlist(zip_file)),
         {:ok, valid?} <-
           File.open(zip_file, [:read, :binary], &valid_entries?(&1, entries, root)) do
      valid?
    else
      _ -> false
    end
  end

  defp valid_entries?(file, entries, root) do
    for({:zip_file, name, _info, _comment, offset, _size} <- entries, do: {name, offset})
    |> Enum.all?(fn {name, offset} -> valid_entry?(file, name, offset, root) end)
  end

  defp valid_entry?(file, name, offset, root) do
    local_name(file, offset) in central_names(name) and inside?(to_string(name), root)
  end

  defp local_name(file, offset) do
    with {:ok,
          <<@local_file_header::little-32, _::binary-size(22), name_length::little-16,
            _extra_length::little-16>>} <- :file.pread(file, offset, 30),
         {:ok, name} <- :file.pread(file, offset + 30, name_length) do
      name
    else
      _ -> nil
    end
  end

  # :zip decodes a name as UTF-8 or byte by byte, depending on the entry's flag.
  defp central_names(name) do
    utf8 = :unicode.characters_to_binary(name)

    if Enum.all?(name, &(&1 < 256)),
      do: [utf8, :erlang.list_to_binary(name)],
      else: [utf8]
  end

  defp inside?(name, root) do
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
