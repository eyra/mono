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
        Logger.error("[Storage.Delivery] delivery error: #{error}")
        {:error, error}

      _ ->
        Logger.notice("[Storage.Delivery] delivery succeeded", ansi_color: :light_magenta)
        :ok
    end
  end

  def deliver(backend, endpoint, panel_info, data, meta_data) do
    Logger.notice("[Storage.Delivery] deliver", ansi_color: :light_magenta)
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
