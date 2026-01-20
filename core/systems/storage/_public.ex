defmodule Systems.Storage.Public do
  use Core, :public
  require Logger

  alias Ecto.Multi
  alias Ecto.Changeset
  alias Core.Repo
  alias Frameworks.Signal
  alias Systems.Rate
  alias Systems.Storage
  alias Systems.Monitor

  def get_endpoint!(id, preload \\ []) do
    Repo.get!(Storage.EndpointModel, id)
    |> Repo.preload(preload)
  end

  def get_endpoint_by!(id, preload \\ []) do
    Repo.get!(Storage.EndpointModel, id)
    |> Repo.preload(preload)
  end

  def prepare_endpoint(special_type, attrs) do
    special_changeset = prepare_endpoint_special(special_type, attrs)

    %Storage.EndpointModel{}
    |> Storage.EndpointModel.changeset(%{})
    |> Storage.EndpointModel.change_special(special_type, special_changeset)
    |> Changeset.put_assoc(:auth_node, auth_module().prepare_node())
  end

  defp prepare_endpoint_special(:builtin, attrs) do
    %Storage.BuiltIn.EndpointModel{}
    |> Storage.BuiltIn.EndpointModel.changeset(attrs)
  end

  defp prepare_endpoint_special(:yoda, attrs) do
    %Storage.Yoda.EndpointModel{}
    |> Storage.Yoda.EndpointModel.changeset(attrs)
  end

  defp prepare_endpoint_special(:aws, attrs) do
    %Storage.AWS.EndpointModel{}
    |> Storage.AWS.EndpointModel.changeset(attrs)
  end

  defp prepare_endpoint_special(:azure, attrs) do
    %Storage.Azure.EndpointModel{}
    |> Storage.Azure.EndpointModel.changeset(attrs)
  end

  def store(
        %Storage.EndpointModel{id: endpoint_id} = endpoint,
        %{key: key, backend: backend, special: special},
        data,
        %{remote_ip: remote_ip} = meta_data
      ) do
    store_start = System.monotonic_time(:millisecond)
    packet_size = byte_size(data)

    Logger.warning(
      "[Storage.Public.store] START endpoint=#{endpoint_id} size=#{packet_size} bytes (#{Float.round(packet_size / 1_000_000, 2)} MB)"
    )

    # raises error when request is denied
    rate_start = System.monotonic_time(:millisecond)
    Rate.Public.request_permission(key, remote_ip, packet_size)
    rate_elapsed = System.monotonic_time(:millisecond) - rate_start
    Logger.warning("[Storage.Public.store] rate_check took #{rate_elapsed}ms")

    # Create human-readable description for debugging (uses same format as filename)
    description = backend.filename(meta_data.identifier)

    # Insert job data first, then create job with job_data_id (instead of full data)
    # This avoids memory spikes from storing large data in Oban job args
    multi_start = System.monotonic_time(:millisecond)

    result =
      Multi.new()
      |> Multi.run(:timing_start, fn _repo, _changes ->
        {:ok, System.monotonic_time(:millisecond)}
      end)
      |> Multi.insert(:job_data, Storage.JobDataModel.prepare(data, description))
      |> Multi.run(:timing_after_insert, fn _repo, %{timing_start: start} ->
        elapsed = System.monotonic_time(:millisecond) - start
        Logger.warning("[Storage.Public.store] DB insert took #{elapsed}ms")
        {:ok, System.monotonic_time(:millisecond)}
      end)
      |> Monitor.Public.multi_log({endpoint, :bytes}, value: packet_size)
      |> Monitor.Public.multi_log({endpoint, :files})
      |> Multi.run(:timing_after_monitor, fn _repo, %{timing_after_insert: start} ->
        elapsed = System.monotonic_time(:millisecond) - start
        Logger.warning("[Storage.Public.store] monitor_log took #{elapsed}ms")
        {:ok, System.monotonic_time(:millisecond)}
      end)
      |> Signal.Public.multi_dispatch({:storage_endpoint, {:monitor, :files}},
        message: %{
          storage_endpoint: endpoint
        }
      )
      |> Multi.run(:timing_after_signal, fn _repo, %{timing_after_monitor: start} ->
        elapsed = System.monotonic_time(:millisecond) - start
        Logger.warning("[Storage.Public.store] signal_dispatch took #{elapsed}ms")
        {:ok, System.monotonic_time(:millisecond)}
      end)
      |> Multi.run(:oban_job, fn _repo, %{job_data: %{id: blob_id}, timing_after_signal: start} ->
        result =
          %{
            endpoint_id: endpoint_id,
            backend: backend,
            special: special,
            blob_id: blob_id,
            meta_data: meta_data
          }
          |> Storage.Delivery.new()
          |> Oban.insert()

        elapsed = System.monotonic_time(:millisecond) - start
        Logger.warning("[Storage.Public.store] oban_insert took #{elapsed}ms")
        result
      end)
      |> Repo.commit()

    multi_elapsed = System.monotonic_time(:millisecond) - multi_start
    total_elapsed = System.monotonic_time(:millisecond) - store_start

    case result do
      {:ok, _} ->
        Logger.warning(
          "[Storage.Public.store] SUCCESS multi=#{multi_elapsed}ms total=#{total_elapsed}ms"
        )

      {:error, step, reason, _} ->
        Logger.error(
          "[Storage.Public.store] FAILED at #{step}: #{inspect(reason)} multi=#{multi_elapsed}ms total=#{total_elapsed}ms"
        )
    end

    result
  end

  def list_files(endpoint) do
    apply_on_special_backend(endpoint, :list_files)
  end

  def delete_files(endpoint) do
    Multi.new()
    |> Monitor.Public.multi_reset({endpoint, :bytes})
    |> Monitor.Public.multi_reset({endpoint, :files})
    |> Signal.Public.multi_dispatch({:storage_endpoint, :delete_files},
      message: %{
        storage_endpoint: endpoint
      }
    )
    |> Multi.run(:delete_files, fn _, _ ->
      case apply_on_special_backend(endpoint, :delete_files) do
        :ok -> {:ok, true}
        {:error, error} -> {:error, error}
      end
    end)
    |> Repo.commit()
  end

  def connected?(special) do
    {_, backend} = Storage.Private.special_info(special)
    connected? = backend.connected?(special)

    if connected? do
      Monitor.Public.log({special, :connected})
    else
      Monitor.Public.reset({special, :connected})
    end

    connected?
  end

  defp apply_on_special_backend(endpoint, function_name) when is_atom(function_name) do
    special = Storage.EndpointModel.special(endpoint)
    {_, backend} = Storage.Private.special_info(special)
    apply(backend, function_name, [special])
  end

  def file_count(endpoint) do
    list_files(endpoint) |> Enum.count()
  end
end

defimpl Core.Persister, for: Systems.Storage.EndpointModel do
  def save(_endpoint, changeset) do
    case Frameworks.Utility.EctoHelper.update_and_dispatch(changeset, :storage_endpoint) do
      {:ok, %{storage_endpoint: storage_endpoint}} -> {:ok, storage_endpoint}
      _ -> {:error, changeset}
    end
  end
end

defimpl Core.Persister, for: Systems.Storage.Yoda.EndpointModel do
  def save(_endpoint, changeset) do
    case Frameworks.Utility.EctoHelper.update_and_dispatch(changeset, :yoda_endpoint) do
      {:ok, %{yoda_endpoint: yoda_endpoint}} -> {:ok, yoda_endpoint}
      _ -> {:error, changeset}
    end
  end
end
