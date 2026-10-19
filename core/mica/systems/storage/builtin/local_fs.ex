defmodule Systems.Storage.BuiltIn.LocalFS do
  @moduledoc """
  Stores donations on the local filesystem under the configured `root_path`.

  The root must not be a statically served folder (such as `upload_path`):
  donations are only handed out through `Systems.Storage.Controller`, which
  checks access to the endpoint.
  """
  @behaviour Systems.Storage.BuiltIn.Special

  @impl true
  def store(folder, filename, data) do
    folder_path = get_full_path(folder)
    File.mkdir_p(folder_path)
    file_path = Path.join(folder_path, filename)

    case File.write(file_path, data) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def list_files(folder) do
    folder_path = get_full_path(folder)
    File.mkdir_p(folder_path)

    File.ls!(folder_path)
    |> Enum.map(fn filename ->
      file_path = Path.join(folder_path, filename)
      {:ok, %File.Stat{mtime: mtime, size: size}} = File.stat(file_path)

      datetime =
        mtime
        |> NaiveDateTime.from_erl!()
        |> DateTime.from_naive!("Etc/UTC")

      %{
        path: filename,
        size: size,
        timestamp: datetime,
        source: {:file, file_path}
      }
    end)
  end

  @impl true
  def delete_files(folder) do
    folder_path = get_full_path(folder)
    File.rm_rf!(folder_path)
    :ok
  end

  defp get_full_path(folder) do
    Path.join(get_root_path(), folder)
  end

  def get_root_path do
    Core.Env.fetch!(__MODULE__) |> Keyword.fetch!(:root_path)
  end
end
