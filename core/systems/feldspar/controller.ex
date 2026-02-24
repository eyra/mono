defmodule Systems.Feldspar.Controller do
  @moduledoc """
  HTTP API endpoints for Feldspar client communication.

  Provides endpoints for:
  - Data donation uploads (large file handling via HTTP instead of WebSocket)
  - Client-side logging (forwarded to AppSignal via Elixir Logger)
  """
  use CoreWeb, {:controller, [formats: [:json]]}

  require Logger

  alias Systems.Assignment
  alias Systems.Feldspar
  alias Systems.Project
  alias Systems.Rate
  alias Systems.Storage

  @valid_log_levels ~w(debug info warn error)

  # ============================================================================
  # Donate endpoint
  # ============================================================================

  @doc """
  Accepts a data donation, stores it as a file, and schedules delivery.

  Expects multipart/form-data with:
  - key: Identifier key for the data
  - context: JSON string containing assignment_id, task, participant, group, panel_info
  - data: File upload containing the data

  Returns:
  - 200 with {status: "ok"} on success
  - 400 if missing required fields (key, data, context) or invalid context
  - 401 if user not authenticated
  - 422 if storage/delivery fails
  - 429 if rate limited
  """
  def donate(conn, %{"key" => key, "data" => %Plug.Upload{} = upload, "context" => context}) do
    Logger.info("[Feldspar] Donation request for key=#{key}")

    with {:ok, context} <- parse_context(context),
         {:ok, _user} <- get_current_user(conn),
         {:ok, data} <- read_upload(upload),
         meta_data <- build_meta_data(conn, key, context),
         :ok <- check_rate_limit(:feldspar_data_donation, meta_data.remote_ip, byte_size(data)),
         {:ok, storage_endpoint} <- get_storage_endpoint(context),
         file_id <- Feldspar.DataDonationFolder.filename(context),
         {:ok, %{id: ^file_id}} <- Feldspar.DataDonationFolder.store(data, file_id),
         :ok <- schedule_delivery(storage_endpoint, file_id, meta_data) do
      Logger.info(
        "[Feldspar] Donation stored and delivery scheduled, key=#{key}, file_id=#{file_id}"
      )

      json(conn, %{status: "ok"})
    else
      {:error, :not_authenticated} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Not authenticated"})

      {:error, :file_read_error, reason} ->
        Logger.error("[Feldspar] Failed to read upload: #{inspect(reason)}")

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to read upload"})

      {:error, :rate_limited, reason} ->
        Logger.warning("[Feldspar] Rate limited: #{reason}")

        conn
        |> put_status(:too_many_requests)
        |> json(%{error: "Rate limited: #{reason}"})

      {:error, :invalid_context} ->
        Logger.error("[Feldspar] Missing or invalid context")

        conn
        |> put_status(:bad_request)
        |> json(%{error: "Missing or invalid context"})

      {:error, :no_storage_endpoint} ->
        Logger.error("[Feldspar] No storage endpoint configured")

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "No storage endpoint configured"})

      {:error, {:scheduling_failed, step, reason}} ->
        Logger.error("[Feldspar] Scheduling failed at step=#{step}: #{inspect(reason)}")

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Scheduling failed"})

      {:error, reason} ->
        Logger.error("[Feldspar] Storage failed: #{inspect(reason)}")

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Storage failed"})
    end
  end

  def donate(conn, params) do
    missing =
      ["key", "data", "context"]
      |> Enum.reject(&Map.has_key?(params, &1))
      |> Enum.join(", ")

    Logger.error("[Feldspar] Missing required fields: #{missing}")

    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required fields: #{missing}"})
  end

  # ============================================================================
  # Log endpoint
  # ============================================================================

  @doc """
  Accepts a log entry from the client and forwards it to Elixir Logger (-> AppSignal).

  Expects JSON with:
  - level: "debug" | "info" | "warn" | "error"
  - message: string
  - context: optional object with additional context (assignment_id, etc.)

  Returns:
  - 200 with {status: "ok"} on success
  - 400 if missing required fields or invalid level
  - 401 if user not authenticated
  - 429 if rate limited
  """
  def log(conn, %{"level" => level, "message" => message} = params) do
    context = params["context"] || %{}

    with {:ok, _user} <- get_current_user(conn),
         :ok <- validate_log_level(level),
         :ok <- check_rate_limit(:feldspar_log, get_remote_ip(conn), 1) do
      log_client_message(level, message, context)
      json(conn, %{status: "ok"})
    else
      {:error, :not_authenticated} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Not authenticated"})

      {:error, :invalid_level} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid level. Must be one of: #{Enum.join(@valid_log_levels, ", ")}"})

      {:error, :rate_limited, reason} ->
        conn
        |> put_status(:too_many_requests)
        |> json(%{error: "Rate limited: #{reason}"})
    end
  end

  def log(conn, params) do
    missing =
      ["level", "message"]
      |> Enum.reject(&Map.has_key?(params, &1))
      |> Enum.join(", ")

    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required fields: #{missing}"})
  end

  # ============================================================================
  # Shared private functions
  # ============================================================================

  defp get_current_user(conn) do
    case conn.assigns[:current_user] do
      nil -> {:error, :not_authenticated}
      user -> {:ok, user}
    end
  end

  defp get_remote_ip(conn) do
    conn.remote_ip
    |> :inet.ntoa()
    |> to_string()
  end

  defp check_rate_limit(service, remote_ip, size) do
    Rate.Public.request_permission(service, remote_ip, size)
    :ok
  rescue
    e in Rate.Public.RateLimitError ->
      {:error, :rate_limited, e.message}
  end

  # ============================================================================
  # Donate-specific private functions
  # ============================================================================

  defp read_upload(%Plug.Upload{path: path}) do
    case File.read(path) do
      {:ok, data} -> {:ok, data}
      {:error, reason} -> {:error, :file_read_error, reason}
    end
  end

  defp get_storage_endpoint(context) do
    assignment_id = context["assignment_id"]

    Logger.info(
      "[Feldspar] Looking up storage endpoint for assignment_id=#{inspect(assignment_id)}"
    )

    if assignment_id && assignment_id != "" do
      with {:ok, assignment} <- get_assignment(assignment_id) do
        Logger.info("[Feldspar] Found assignment id=#{assignment.id}")

        case Project.Public.get_storage_endpoint_by(assignment) do
          {:ok, endpoint} ->
            Logger.info("[Feldspar] Found storage endpoint")
            {:ok, endpoint}

          {:error, {:storage_endpoint, :not_available}} ->
            Logger.error("[Feldspar] Storage endpoint not available for assignment")
            {:error, :no_storage_endpoint}
        end
      end
    else
      Logger.error("[Feldspar] No assignment_id in context")
      {:error, :no_storage_endpoint}
    end
  end

  defp schedule_delivery(storage_endpoint, file_id, meta_data) do
    case Storage.Public.deliver_file(storage_endpoint, file_id, meta_data) do
      {:ok, _} -> :ok
      {:error, step, reason, _} -> {:error, {:scheduling_failed, step, reason}}
    end
  end

  defp get_assignment(assignment_id) do
    Logger.info("[Feldspar] Fetching assignment id=#{inspect(assignment_id)}")

    case Assignment.Public.get(assignment_id, Assignment.Model.preload_graph(:down)) do
      nil ->
        Logger.error("[Feldspar] Assignment not found id=#{inspect(assignment_id)}")
        {:error, :assignment_not_found}

      assignment ->
        Logger.info("[Feldspar] Assignment found, has workflow=#{assignment.workflow != nil}")
        {:ok, assignment}
    end
  end

  defp parse_context(nil), do: {:error, :invalid_context}
  defp parse_context(""), do: {:error, :invalid_context}
  defp parse_context("{}"), do: {:error, :invalid_context}

  defp parse_context(json) when is_binary(json) do
    case Jason.decode(json) do
      {:ok, map} when map == %{} -> {:error, :invalid_context}
      {:ok, map} -> {:ok, map}
      {:error, _} -> {:error, :invalid_context}
    end
  end

  defp build_meta_data(conn, key, context) do
    %{
      remote_ip: get_remote_ip(conn),
      panel_info: context["panel_info"] || %{},
      identifier: [
        [:assignment, context["assignment_id"] || ""],
        [:task, context["task"] || ""],
        [:participant, context["participant"] || ""],
        [:source, context["group"] || ""],
        [:key, key || ""]
      ]
    }
  end

  # ============================================================================
  # Log-specific private functions
  # ============================================================================

  defp validate_log_level(level) when level in @valid_log_levels, do: :ok
  defp validate_log_level(_), do: {:error, :invalid_level}

  defp log_client_message(level, message, context) do
    formatted_context = format_log_context(context)
    full_message = "[Feldspar.Client] #{message}#{formatted_context}"

    case level do
      "debug" -> Logger.debug(full_message)
      "info" -> Logger.info(full_message)
      "warn" -> Logger.warning(full_message)
      "error" -> Logger.error(full_message)
    end
  end

  defp format_log_context(context) when context == %{}, do: ""

  defp format_log_context(context) do
    formatted = Enum.map_join(context, ", ", fn {k, v} -> "#{k}=#{inspect(v)}" end)
    " [#{formatted}]"
  end
end
