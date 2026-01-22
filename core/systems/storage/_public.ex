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

  @doc """
  Schedules delivery of a file to a storage endpoint.
  The file_id refers to a file in the configured temp file store.
  """
  def deliver_file(
        %Storage.EndpointModel{id: endpoint_id} = endpoint,
        file_id,
        meta_data
      ) do
    %{backend: backend, special: special} = storage_info(endpoint)

    result =
      Multi.new()
      |> Monitor.Public.multi_log({endpoint, :bytes}, value: temp_file_store().size(file_id))
      |> Monitor.Public.multi_log({endpoint, :files})
      |> Signal.Public.multi_dispatch({:storage_endpoint, {:monitor, :files}},
        message: %{
          storage_endpoint: endpoint
        }
      )
      |> Multi.run(:oban_job, fn _repo, _ ->
        %{
          endpoint_id: endpoint_id,
          backend: backend,
          special: special,
          file_id: file_id,
          meta_data: meta_data
        }
        |> Storage.Delivery.new(queue: Storage.Private.storage_delivery_queue())
        |> Oban.insert()
      end)
      |> Repo.commit()

    case result do
      {:ok, _} ->
        :ok

      {:error, step, reason, _} ->
        Logger.error("[Storage.Public.deliver_file] FAILED at #{step}: #{inspect(reason)}")
    end

    result
  end

  def store(
        %Storage.EndpointModel{id: endpoint_id} = endpoint,
        %{key: key, backend: backend, special: special},
        data,
        %{remote_ip: remote_ip, identifier: identifier} = meta_data
      ) do
    packet_size = byte_size(data)

    # raises error when request is denied
    Rate.Public.request_permission(key, remote_ip, packet_size)

    # Generate filename using the backend's filename function (same as S3 destination)
    file_id = backend.filename(identifier)

    # Store data as file first, then create Oban job with file_id
    # This avoids memory spikes from storing large data in Oban job args or database
    case temp_file_store().store(data, file_id) do
      {:ok, %{id: ^file_id}} ->
        result =
          Multi.new()
          |> Monitor.Public.multi_log({endpoint, :bytes}, value: packet_size)
          |> Monitor.Public.multi_log({endpoint, :files})
          |> Signal.Public.multi_dispatch({:storage_endpoint, {:monitor, :files}},
            message: %{
              storage_endpoint: endpoint
            }
          )
          |> Multi.run(:oban_job, fn _repo, _ ->
            %{
              endpoint_id: endpoint_id,
              backend: backend,
              special: special,
              file_id: file_id,
              meta_data: meta_data
            }
            |> Storage.Delivery.new(queue: Storage.Private.storage_delivery_queue())
            |> Oban.insert()
          end)
          |> Repo.commit()

        case result do
          {:ok, _} ->
            :ok

          {:error, step, reason, _} ->
            Logger.error("[Storage.Public.store] FAILED at #{step}: #{inspect(reason)}")
            # Clean up the file if the transaction failed
            temp_file_store().delete(file_id)
        end

        result

      {:error, reason} ->
        Logger.error("[Storage.Public.store] FAILED to store file: #{inspect(reason)}")
        {:error, :file_storage, reason, %{}}
    end
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

  defp temp_file_store do
    Application.get_env(:core, :temp_file_store)[:module]
  end

  @doc """
  Returns storage info for an endpoint, including the backend module and special config.
  """
  def storage_info(storage_endpoint) do
    special = Storage.EndpointModel.special(storage_endpoint)
    {key, backend} = Storage.Private.special_info(special)
    %{key: key, special: special, backend: backend}
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
