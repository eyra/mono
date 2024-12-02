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
    case deliver(args) do
      {:error, error} ->
        Logger.error("[Storage.Delivery] delivery error: #{error}")
        {:error, error}

      _ ->
        Logger.notice("[Storage.Delivery] delivery succeeded", ansi_color: :light_magenta)
        Signal.Public.dispatch({:storage_delivery, :delivered}, %{storage_delivery: args})
        :ok
    end
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

  def deliver(
        %{
          "backend" => backend,
          "special" => special,
          "data" => data,
          "meta_data" => meta_data
        } = _job
      ) do
    deliver(String.to_existing_atom(backend), special, data, meta_data)
  end
end
