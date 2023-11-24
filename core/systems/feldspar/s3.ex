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
    "#{public_url}/#{object_key(id)}"
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
    {:ok, zip_handle} = :zip.zip_open(to_charlist(zip_file), [:memory])

    # Read the zip file names and skip the comment (first item)
    {:ok, [_ | contents]} = :zip.zip_list_dir(zip_handle)

    contents
    |> Enum.map(fn {:zip_file, file, info, _, _, _} -> {file, info} end)
    |> Task.async_stream(&upload_file(&1, zip_handle, target, s3_settings()),
      max_concurrency: 10
    )
    |> Stream.run()
  end

  defp upload_file({name, info}, zip_handle, target, settings) do
    if is_regular_file(info) do
      {:ok, {_, data}} = :zip.zip_get(name, zip_handle)

      S3.put_object(
        Access.fetch!(settings, :bucket),
        "#{object_key(target)}/#{name}",
        data,
        content_type: content_type(name)
      )
      |> backend().request!()
    end
  end

  defp content_type(name), do: MIME.from_path(name)

  @doc """
    See: https://www.erlang.org/doc/man/file#type-file_info
    Files types: device | directory | other | regular | symlink | undefined
    Only real files (aka :regular) can/should be uploaded.
  """
  def is_regular_file({:file_info, _, :regular, _, _, _, _, _, _, _, _, _, _, _}), do: true
  def is_regular_file(_), do: false

  defp object_key(id) do
    prefix = Access.get(s3_settings(), :prefix, nil)

    [prefix, id]
    |> Enum.filter(&(&1 != nil))
    |> Enum.join("/")
  end

  defp s3_settings do
    Application.fetch_env!(:core, :feldspar)
  end

  defp backend do
    # Allow mocking
    Access.get(s3_settings(), :s3_backend, ExAws)
  end
end
