defmodule Systems.Feldspar.DataDonationFolder do
  @moduledoc """
  Manages a folder of data donation files.

  Files are stored in a configurable directory with a unique ID and .dat extension.
  This avoids memory pressure from large uploads by storing data on the filesystem.
  """

  require Logger

  @doc """
  Generates a unique filename from context map for temporary storage.
  """
  def filename(%{} = context) do
    identifier = [
      [:assignment, context["assignment_id"]],
      [:task, context["task"]],
      [:participant, context["participant"]],
      [:source, context["group"]],
      [:key, context["key"]]
    ]

    Systems.Storage.Filename.generate_unique(identifier)
  end

  @doc """
  Stores data as a file with the given file_id.
  """
  def store(data, file_id) when is_binary(data) and is_binary(file_id) do
    path = file_path(file_id)

    ensure_directory_exists()

    case File.write(path, data, [:binary, :sync]) do
      :ok ->
        Logger.info("[DataDonationFolder] Stored #{file_id}, #{byte_size(data)} bytes")
        {:ok, %{id: file_id, size: byte_size(data)}}

      {:error, reason} ->
        Logger.error("[DataDonationFolder] Failed to write #{path}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Reads a data donation file from the filesystem.
  Returns {:ok, data} or {:error, reason}.
  """
  def read(file_id) do
    path = file_path(file_id)

    case File.read(path) do
      {:ok, data} ->
        {:ok, data}

      {:error, :enoent} ->
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("[DataDonationFolder] Failed to read #{path}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Deletes a data donation file after successful delivery.
  """
  def delete(file_id) do
    path = file_path(file_id)

    case File.rm(path) do
      :ok ->
        Logger.info("[DataDonationFolder] Deleted file #{file_id}")
        :ok

      {:error, :enoent} ->
        # Already deleted, that's fine
        :ok

      {:error, reason} ->
        Logger.error("[DataDonationFolder] Failed to delete #{path}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Returns the size of a data donation file, or 0 if not found.
  """
  def size(file_id) do
    path = file_path(file_id)

    case File.stat(path) do
      {:ok, %{size: size}} -> size
      {:error, _} -> 0
    end
  end

  @doc """
  Lists all data donation files with their metadata.
  Returns a list of %{id: file_id, path: full_path, size: bytes, created_at: DateTime}.
  """
  def list_all do
    ensure_directory_exists()

    case File.ls(data_donation_path()) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".dat"))
        |> Enum.map(&file_metadata/1)
        |> Enum.reject(&is_nil/1)

      {:error, reason} ->
        Logger.error("[DataDonationFolder] Failed to list files: #{inspect(reason)}")
        []
    end
  end

  defp file_metadata(filename) do
    file_id = String.replace_suffix(filename, ".dat", "")
    path = file_path(file_id)

    case File.stat(path, time: :posix) do
      {:ok, stat} ->
        %{
          id: file_id,
          path: path,
          size: stat.size,
          created_at: DateTime.from_unix!(stat.ctime)
        }

      {:error, _} ->
        nil
    end
  end

  @doc """
  Returns aggregate statistics about stored data donations.
  """
  def stats do
    files = list_all()

    %{
      file_count: length(files),
      total_size: Enum.reduce(files, 0, &(&1.size + &2)),
      oldest_file:
        files
        |> Enum.min_by(& &1.created_at, DateTime, fn -> nil end)
        |> case do
          nil -> nil
          file -> file.created_at
        end
    }
  end

  @doc """
  Deletes all files older than the given number of hours.
  Returns the count of deleted files.
  """
  def cleanup_older_than(hours) do
    cutoff = DateTime.utc_now() |> DateTime.add(-hours * 3600, :second)

    list_all()
    |> Enum.filter(fn %{created_at: created_at} ->
      DateTime.compare(created_at, cutoff) == :lt
    end)
    |> Enum.reduce(0, fn %{id: file_id}, count ->
      case delete(file_id) do
        :ok -> count + 1
        {:error, _} -> count
      end
    end)
  end

  defp data_donation_path do
    Application.get_env(:core, :feldspar_data_donation)[:path] ||
      raise "FELDSPAR_DATA_DONATION_PATH not configured"
  end

  defp file_path(file_id) do
    Path.join(data_donation_path(), "#{file_id}.dat")
  end

  defp ensure_directory_exists do
    path = data_donation_path()

    case File.mkdir_p(path) do
      :ok -> :ok
      {:error, :eexist} -> :ok
      {:error, reason} -> raise "Failed to create directory #{path}: #{inspect(reason)}"
    end
  end
end
