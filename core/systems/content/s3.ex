defmodule Systems.Content.S3 do
  alias ExAws.S3

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
end
