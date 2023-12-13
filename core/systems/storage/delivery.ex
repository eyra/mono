defmodule Systems.Storage.Delivery do
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
        Logger.error("Data delivery error: #{error}")
        {:error, error}

      _ ->
        Logger.debug("Data delivery succeeded")
        :ok
    end
  end

  defp deliver(
         %{
           "backend" => backend,
           "endpoint" => endpoint,
           "panel_info" => panel_info,
           "data" => data,
           "meta_data" => meta_data
         } = job
       ) do
    Logger.warn("[Storage.Delivery] deliver: #{inspect(job)}")

    String.to_existing_atom(backend).store(endpoint, panel_info, data, meta_data)
  end
end
