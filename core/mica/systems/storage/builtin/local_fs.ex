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
    # A donation key may contain "/" (e.g. "<run>/summary"), which nests the file;
    # a ".." segment must not lead it out of the endpoint folder.
    case Path.safe_relative(filename) do
      {:ok, relative_path} -> write(Path.join(get_full_path(folder), relative_path), data)
      :error -> {:error, :unsafe_filename}
    end
  end

  defp write(file_path, data) do
    File.mkdir_p(Path.dirname(file_path))

    case File.write(file_path, data) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def list_files(folder) do
    folder_path = get_full_path(folder)
    File.mkdir_p(folder_path)

    Path.join(folder_path, "**/*")
    |> Path.wildcard()
    |> Enum.filter(&File.regular?/1)
    |> Enum.map(fn file_path ->
      filename = Path.relative_to(file_path, folder_path)
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

  @legacy_folder_prefixes ["project_node=", "assignment="]

  # The message must stay well below Logger's `truncate` limit (8 KiB by default), which
  # cuts it off at boot, so it lists only some folders and moves them with one glob per prefix.
  @listed_folders 10

  # Symlinked folders get one `mv` each, up to this many; above it, one loop per prefix.
  @moved_links 10

  @doc """
  Raises when `upload_path` still holds endpoint folders (`project_node=<id>`,
  or `assignment=<id>` for endpoints created before storage moved to projects).

  Earlier versions stored donations there, where they are served without
  authentication and left out of the export. Files are never moved in code:
  the error names the folders and the commands to move them to `root_path`.

  When the default log handler does not use Logger's own formatter (production
  logs JSON), the message is also written to stderr as plain text first, so the
  commands can be copied as they are.
  """
  def check_upload_path!(upload_path, root_path \\ get_root_path()) do
    case legacy_folders(upload_path) do
      [] ->
        :ok

      folders ->
        message = legacy_folders_message(upload_path, root_path, folders)
        print_plain_text(message)
        raise message
    end
  end

  defp print_plain_text(message) do
    if not plain_text_log?(), do: IO.puts(:stderr, message)
  end

  defp plain_text_log? do
    case Application.get_env(:logger, :default_handler) do
      [_ | _] = config ->
        match?({Logger.Formatter, _}, Keyword.get(config, :formatter, {Logger.Formatter, []}))

      _ ->
        true
    end
  end

  defp legacy_folders(nil), do: []

  defp legacy_folders(upload_path) do
    case File.ls(upload_path) do
      {:ok, names} ->
        names
        |> Enum.filter(&legacy_folder?(upload_path, &1))
        |> Enum.sort()

      {:error, _} ->
        []
    end
  end

  defp legacy_folder?(upload_path, name) do
    String.starts_with?(name, @legacy_folder_prefixes) and File.dir?(Path.join(upload_path, name))
  end

  defp legacy_folders_message(upload_path, root_path, folders) do
    upload_path = Path.expand(upload_path)
    root_path = Path.expand(root_path)

    """
    Donations from an earlier version are still in UPLOAD_PATH (#{upload_path}), \
    which is served without authentication (#{length(folders)} folders):

    #{listed_folders(upload_path, folders)}

    Stop every node of this app and move these folders to STORAGE_PATH (#{root_path}):

        mkdir -p #{shell_quote(root_path)}
    #{move_commands(upload_path, root_path, folders)}

    Then start the app again.
    """
  end

  defp listed_folders(upload_path, folders) do
    {listed, rest} = Enum.split(folders, @listed_folders)
    lines = Enum.map(listed, &"    #{Path.join(upload_path, &1)}")

    case rest do
      [] -> Enum.join(lines, "\n")
      _ -> Enum.join(lines ++ ["    ... and #{length(rest)} more"], "\n")
    end
  end

  # Symlinked folders move first, without a trailing slash: `mv link/` fails on Linux
  # ("Not a directory") and moves the link's target instead on macOS. Then one glob per
  # prefix that still has folders, so no glob is left unmatched; the trailing slash makes
  # it match folders only.
  defp move_commands(upload_path, root_path, folders) do
    {links, dirs} = Enum.split_with(folders, &symlink?(upload_path, &1))

    (link_commands(upload_path, root_path, links) ++ glob_commands(upload_path, root_path, dirs))
    |> Enum.map_join("\n", &"    #{&1}")
  end

  defp link_commands(upload_path, root_path, links) when length(links) <= @moved_links do
    Enum.map(links, &"mv #{shell_quote(Path.join(upload_path, &1))} #{shell_quote(root_path)}/")
  end

  defp link_commands(upload_path, root_path, links) do
    links
    |> prefixes()
    |> Enum.map(fn prefix ->
      ~s(for f in #{shell_quote(upload_path)}/#{prefix}*; do ) <>
        ~s(if [ -L "$f" ] && [ -d "$f" ]; then mv "$f" #{shell_quote(root_path)}/; fi; done)
    end)
  end

  defp glob_commands(upload_path, root_path, dirs) do
    dirs
    |> prefixes()
    |> Enum.map(&"mv #{shell_quote(upload_path)}/#{&1}*/ #{shell_quote(root_path)}/")
  end

  defp prefixes(folders) do
    @legacy_folder_prefixes
    |> Enum.filter(fn prefix -> Enum.any?(folders, &String.starts_with?(&1, prefix)) end)
    |> Enum.sort()
  end

  defp symlink?(upload_path, name) do
    match?({:ok, %File.Stat{type: :symlink}}, File.lstat(Path.join(upload_path, name)))
  end

  defp shell_quote(path) do
    if path =~ ~r/^[\w\/.=+@%:-]+$/ do
      path
    else
      "'" <> String.replace(path, "'", "'\\''") <> "'"
    end
  end
end
