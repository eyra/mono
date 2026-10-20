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

  @legacy_folder_prefix "project_node="

  @doc """
  Raises when `upload_path` still holds endpoint folders (`project_node=<id>`).

  Earlier versions stored donations there, where they are served without
  authentication and left out of the export. Files are never moved in code:
  the error names the folders and the command to move them to `root_path`.
  """
  def check_upload_path!(upload_path, root_path \\ get_root_path()) do
    case legacy_folders(upload_path) do
      [] -> :ok
      folders -> raise legacy_folders_message(upload_path, root_path, folders)
    end
  end

  defp legacy_folders(nil), do: []

  defp legacy_folders(upload_path) do
    case File.ls(upload_path) do
      {:ok, names} ->
        names
        |> Enum.filter(&String.starts_with?(&1, @legacy_folder_prefix))
        |> Enum.map(&Path.join(upload_path, &1))
        |> Enum.filter(&File.dir?/1)
        |> Enum.sort()

      {:error, _} ->
        []
    end
  end

  defp legacy_folders_message(upload_path, root_path, folders) do
    upload_path = Path.expand(upload_path)
    root_path = Path.expand(root_path)

    """
    Donations from an earlier version are still in UPLOAD_PATH (#{upload_path}), \
    which is served without authentication:

    #{Enum.map_join(folders, "\n", &"    #{Path.expand(&1)}")}

    Stop every node of this app and move these folders to STORAGE_PATH (#{root_path}):

        mkdir -p #{shell_quote(root_path)}
        mv #{shell_quote(upload_path)}/#{@legacy_folder_prefix}* #{shell_quote(root_path)}/

    Then start the app again.
    """
  end

  defp shell_quote(path) do
    if path =~ ~r/^[\w\/.=+@%:-]+$/ do
      path
    else
      "'" <> String.replace(path, "'", "'\\''") <> "'"
    end
  end
end
