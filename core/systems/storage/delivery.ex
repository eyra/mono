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

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    case deliver(args) do
      {:error, error} ->
        Logger.error("Data delivery error: #{error}")
        {:error, error}

      _ ->
        Logger.info("Data delivery succeeded")
        :ok
    end
  end

  def deliver(backend, endpoint, panel_info, data, meta_data) do
    Logger.warn("[Storage.Delivery] deliver")
    backend.store(endpoint, panel_info, data, meta_data)
  end

  def deliver(
        %{
          "backend" => backend,
          "endpoint" => endpoint,
          "panel_info" => panel_info,
          "data" => data,
          "meta_data" => meta_data
        } = _job
      ) do
    deliver(String.to_existing_atom(backend), endpoint, panel_info, data, meta_data)
  end
end
