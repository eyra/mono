defmodule Systems.Content.S3 do
  use Gettext, backend: CoreWeb.Gettext
  alias ExAws.S3

  defmodule Error do
    defexception [:message]

    def failed_to_setup_stream(error) do
      %__MODULE__{message: "Failed to setup S3 stream: #{inspect(error)}"}
    end
  end

  def store(file, original_filename) do
    bucket = Access.fetch!(s3_settings(), :bucket)
    uuid = Ecto.UUID.generate()
    extname = Path.extname(original_filename)
    filename = "#{uuid}#{extname}"

    upload_file(file, filename, bucket)
    filename
  end

  def remove(filename) do
    bucket = Access.fetch!(s3_settings(), :bucket)
    object_key = "#{object_key(filename)}"

    S3.delete_object(bucket, object_key)
    |> backend().request!()
  end

  def get_public_url(filename) do
    settings = s3_settings()
    public_url = Access.get(settings, :public_url)
    "#{public_url}/#{object_key(filename)}"
  end

  defp upload_file(file, filename, bucket) do
    {:ok, data} = File.read(file)
    object_key = "#{object_key(filename)}"

    S3.put_object(
      bucket,
      object_key,
      data,
      content_type: content_type(filename)
    )
    |> backend().request!()
  end

  defp content_type(name), do: MIME.from_path(name)

  defp object_key(filename) do
    prefix = Access.get(s3_settings(), :prefix, nil)

    [prefix, filename]
    |> Enum.filter(&(&1 != nil))
    |> Enum.join("/")
  end

  defp s3_settings do
    Application.fetch_env!(:core, :content)
  end

  defp backend do
    # Allow mocking
    Access.get(s3_settings(), :s3_backend, ExAws)
  end

  @doc """
  Stream file content from S3 in chunks without loading into memory.
  Returns {:ok, stream} or {:error, reason}
  """
  def stream(path) do
    bucket = Access.fetch!(s3_settings(), :bucket)

    # Extract object key from path/URL
    object_key =
      if String.contains?(path, bucket) do
        # Full S3 URL - extract key from URL
        uri = URI.parse(path)
        String.trim_leading(uri.path, "/")
      else
        # Just the filename/key
        object_key(path)
      end

    # Create S3 download stream with configurable chunk size
    chunk_size = get_stream_chunk_size()

    stream =
      bucket
      |> ExAws.S3.download_file(object_key, :memory, chunk_size: chunk_size)
      |> ExAws.stream!()
      |> Stream.map(fn chunk -> chunk end)

    {:ok, stream}
  rescue
    error ->
      {:error, Error.failed_to_setup_stream(error)}
  end

  defp get_stream_chunk_size do
    Application.fetch_env!(:core, :paper)
    |> Keyword.fetch!(:ris_stream_chunk_size)
  end
end
