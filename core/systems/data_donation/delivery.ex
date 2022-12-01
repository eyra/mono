defmodule Systems.DataDonation.Delivery do
  defmodule DeliveryError do
    @moduledoc false
    defexception [:message]
  end

  use Oban.Worker,
    queue: :data_donation_delivery,
    priority: 1,
    max_attempts: 3,
    unique: [period: 30]

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    case deliver(args) do
      {:error, error} ->
        Logger.error("Data-donation delivery error: #{error}")
        {:error, error}

      _ ->
        Logger.debug("Data-donation delivery succeeded")
        :ok
    end
  end

  defp deliver(%{
         "storage_key" => storage_key,
         "state" => state,
         "vm" => vm,
         "data" => data
       }) do
    storage = storage(storage_key)
    storage.store(state, vm, data)
  end

  defp config() do
    Application.fetch_env!(:core, :data_donation_storage_backend)
  end

  defp storage(storage_key) do
    config = config()

    case Keyword.get(config, String.to_atom(storage_key)) do
      nil ->
        raise DeliveryError, "Could not deliver donated data, invalid config for #{storage_key}"

      value ->
        value
    end
  end
end
