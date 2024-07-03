defmodule Systems.Storage.BuiltIn.S3 do
  @behaviour Systems.Storage.BuiltIn.Special
  alias ExAws.S3

  @impl true
  def store(folder, filename, data) do
    filepath = Path.join(folder, filename)
    object_key = object_key(filepath)
    content_type = content_type(object_key)
    bucket = Access.fetch!(settings(), :bucket)

    S3.put_object(bucket, object_key, data, content_type: content_type)
    |> backend().request!()
  end

  @impl true
  def list_files(folder) do
    bucket = Access.fetch!(settings(), :bucket)
    prefix = object_key(folder) <> "/"

    %{body: %{contents: contents}} =
      S3.list_objects(bucket, prefix: prefix)
      |> backend().request!()

    contents
    |> Enum.map(fn %{key: key, size: size, last_modified: last_modified} ->
      {:ok, url} =
        :s3
        |> ExAws.Config.new([])
        |> S3.presigned_url(:get, bucket, key, expires_in: 3600)

      %{key: key, size: size, last_modified: last_modified, url: url}
    end)
    |> Enum.map(fn %{key: key, size: size, last_modified: last_modified, url: url} ->
      path = String.replace_prefix(key, prefix, "")

      timestamp =
        case Timex.parse(last_modified, "{ISO:Extended:Z}") do
          {:ok, result} -> result
          _ -> nil
        end

      %{path: path, size: String.to_integer(size), timestamp: timestamp, url: url}
    end)
  end

  @impl true
  def delete_files(folder) do
    bucket = Access.fetch!(settings(), :bucket)
    prefix = object_key(folder) <> "/"

    stream =
      S3.list_objects(bucket, prefix: prefix)
      |> backend().stream!()
      |> Stream.map(& &1.key)

    result =
      S3.delete_all_objects(bucket, stream)
      |> backend().request!()

    errors = Enum.reject(result, &{&1.status_code != 200})

    if Enum.empty?(errors) do
      :ok
    else
      {:error, :some_files_not_deleted}
    end
  end

  defp object_key(filepath) do
    if prefix = Access.get(settings(), :prefix, nil) do
      Path.join(prefix, filepath)
    else
      filepath
    end
  end

  defp content_type(name), do: MIME.from_path(name)

  defp settings do
    Application.fetch_env!(:core, Systems.Storage.BuiltIn.S3)
  end

  defp backend do
    # Allow mocking
    Access.get(settings(), :s3_backend, ExAws)
  end
end
