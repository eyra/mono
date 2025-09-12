defmodule Systems.Content.LocalFS do
  use CoreWeb, :verified_routes
  use Gettext, backend: CoreWeb.Gettext

  defmodule Error do
    defexception [:message]

    def file_not_found(full_path) do
      %__MODULE__{message: "File not found: #{inspect(full_path)}"}
    end
  end

  def public_path, do: "/uploads"

  def get_public_url(path) do
    filename = Path.basename(path)
    base_url = get_base_url()
    "#{base_url}/uploads/#{filename}"
  end

  def store(path, original_filename) do
    uuid = Ecto.UUID.generate()
    root_path = get_root_path()
    new_path = "#{root_path}/#{uuid}_#{original_filename}"
    File.cp!(path, new_path)
    new_path
  end

  def get_root_path do
    Application.get_env(:core, :upload_path)
  end

  def get_base_url do
    Application.get_env(:core, :base_url)
  end

  def remove(path) do
    with {:ok, _} <- File.rm_rf(path) do
      :ok
    end
  end

  @doc """
  Stream file content in chunks without loading into memory.
  Returns {:ok, stream} or {:error, reason}
  """
  def stream(path) do
    # For LocalFS, path could be either URL or direct path
    full_path =
      if String.contains?(path, "/uploads/") do
        # URL format: http://localhost/uploads/uuid_filename.ris
        # Extract filename from URL and construct local path
        filename = Path.basename(path)
        Path.join(get_root_path(), filename)
      else
        # Direct file path
        path
      end

    chunk_size = get_stream_chunk_size()

    if File.exists?(full_path) do
      stream = create_file_stream(full_path, chunk_size)
      {:ok, stream}
    else
      {:error, Error.file_not_found(full_path)}
    end
  end

  defp create_file_stream(full_path, chunk_size) do
    Stream.resource(
      # Start: open file
      fn -> File.open!(full_path, [:read, :binary, :raw, read_ahead: chunk_size]) end,

      # Next: read chunks
      fn device ->
        case IO.binread(device, chunk_size) do
          :eof -> {:halt, device}
          data -> {[data], device}
        end
      end,

      # Cleanup: close file
      fn device -> File.close(device) end
    )
  end

  defp get_stream_chunk_size do
    Application.fetch_env!(:core, :paper)
    |> Keyword.fetch!(:ris_stream_chunk_size)
  end
end
