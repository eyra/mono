defmodule Systems.Storage.Delivery do
  defmodule DeliveryError do
    @moduledoc false
    defexception [:message]
  end

  use Oban.Worker,
    queue: :storage_delivery,
    priority: 1,
    max_attempts: 3,
    unique: [period: 30]

  require Logger

  alias Frameworks.Signal

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    case deliver_from_file(args) do
      {:error, error} ->
        Logger.error("[Storage.Delivery] delivery error: #{inspect(error)}")
        {:error, error}

      :ok ->
        Logger.notice("[Storage.Delivery] delivery succeeded", ansi_color: :light_magenta)
        Signal.Public.dispatch({:storage_delivery, :delivered}, %{storage_delivery: args})
        :ok

      {:discard, reason} ->
        Logger.warning("[Storage.Delivery] discarding job: #{reason}")
        {:discard, reason}
    end
  end

  # Read data from filesystem using file_id
  defp deliver_from_file(%{"file_id" => file_id} = args) do
    case temp_file_store().read(file_id) do
      {:error, :not_found} ->
        # File already deleted (duplicate delivery?) - discard job
        {:discard, "File #{file_id} not found - already processed or expired"}

      {:ok, data} ->
        # Deliver the data, cleanup worker handles file deletion
        deliver_data(args, data)

      {:error, reason} ->
        Logger.error("[Storage.Delivery] Failed to read file #{file_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Legacy path: support jobs that have data directly (for rolling deployment)
  defp deliver_from_file(%{"data" => data} = args) do
    deliver_data(args, data)
  end

  defp deliver_data(
         %{
           "backend" => backend,
           "special" => special,
           "meta_data" => meta_data
         },
         data
       ) do
    deliver(String.to_existing_atom(backend), special, data, meta_data)
  end

  def deliver(backend, endpoint, data, meta_data) do
    Logger.notice("[Storage.Delivery] delivery started, #{byte_size(data)} bytes",
      ansi_color: :light_magenta
    )

    try do
      backend.store(endpoint, data, meta_data)
    rescue
      e ->
        Logger.error(mask_sensitive_data(Exception.format(:error, e, __STACKTRACE__)))
        reraise e, __STACKTRACE__
    end
  end

  defp mask_sensitive_data(string) do
    [:password, :user, :secret_access_key, :sas_token]
    |> Enum.reduce(string, fn key, acc -> mask(key, acc) end)
  end

  defp mask(key, string) do
    case Regex.run(~r"\"#{key}\" => \"([^\"]*)\"", string) do
      [_, value] -> String.replace(string, value, "************")
      _ -> string
    end
  end

  defp temp_file_store do
    Application.get_env(:core, :temp_file_store)[:module]
  end
end
