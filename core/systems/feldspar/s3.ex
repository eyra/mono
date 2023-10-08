defmodule Systems.Feldspar.S3 do
  alias ExAws.S3

  def store(zip_file) do
    id = Ecto.UUID.generate()
    :ok = upload_zip_content(zip_file, id)
    id
  end

  def get_public_url(id) do
    settings = s3_settings()
    public_url = Access.get(settings, :public_url)
    "#{public_url}/#{object_key(id)}/index.html"
  end

  def remove(id) do
    bucket = Access.fetch!(s3_settings(), :bucket)

    objects =
      S3.list_objects_v2(bucket, prefix: object_key(id))
      |> backend().request!()
      |> get_in([:body, :contents])
      |> Enum.map(&Access.fetch!(&1, :key))

    S3.delete_all_objects(bucket, objects)
    |> backend().request!()

    :ok
  end

  defp upload_zip_content(zip_file, target) do
    settings = s3_settings()

    {:ok, zip_handle} = :zip.zip_open(to_charlist(zip_file), [:memory])

    upload_file = fn file ->
      {:ok, {_, data}} = :zip.zip_get(file, zip_handle)

      S3.put_object(
        Access.fetch!(settings, :bucket),
        "#{object_key(target)}/#{file}",
        data
      )
      |> backend().request!()
    end

    # Read the zip file names and skip the comment (first item)
    {:ok, [_ | contents]} = :zip.zip_list_dir(zip_handle)

    contents
    |> Enum.map(fn {:zip_file, file, _, _, _, _} -> file end)
    |> Task.async_stream(upload_file, max_concurrency: 10)
    |> Stream.run()
  end

  defp object_key(id) do
    prefix = Access.get(s3_settings(), :prefix, "")
    "#{prefix}#{id}"
  end

  defp s3_settings do
    Application.fetch_env!(:core, :feldspar)
  end

  defp backend do
    # Allow mocking
    Access.get(s3_settings(), :s3_backend, ExAws)
  end
end
