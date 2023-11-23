defmodule Systems.Feldspar.S3 do
  alias ExAws.S3

  require Logger

  def store(zip_file) do
    id = Ecto.UUID.generate()
    :ok = upload_zip_content(zip_file, id)
    id
  end

  def get_public_url(id) do
    settings = s3_settings() |> dbg()
    public_url = Access.get(settings, :public_url) |> dbg()
    "#{public_url}/#{object_key(id)}" |> dbg()
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
    |> Task.async_stream(&upload_file(&1, zip_handle, target, s3_settings()), max_concurrency: 10, timeout: 60000)
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
      |> dbg()
    else
      Logger.info("[Feldspar.S3] Skip uploading: #{name}")
    end
  end

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

  defp content_type("html"), do: "text/html"
  # defp content_type("js"), do: "text/javascript"
  defp content_type("css"), do: "text/css"
  # defp content_type("svg"), do: "image/svg+xml"
  # defp content_type("ico"), do: "image/x-icon"
  # defp content_type("whl"), do: " application/zip"
  # defp content_type("json"), do: "application/json"
  # defp content_type("ts"), do: "application/typescript"
  # defp content_type("tsx"), do: "application/typescript"
  defp content_type(nil), do: "text/html"

  defp content_type(name) do
    "#{name}"
    |> String.split(".")
    |> List.last()
    |> content_type()
  end
end
