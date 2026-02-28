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
  def donate(conn, %{"key" => key, "data" => %Plug.Upload{} = upload, "context" => context_json}) do
    case parse_context(context_json) do
      {:ok, context} ->
        do_donate(conn, key, upload, context)

      {:error, :invalid_context} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Missing or invalid context"})
    end
  end

  def donate(conn, params) do
    missing =
      ["key", "data", "context"]
      |> Enum.reject(&Map.has_key?(params, &1))
      |> Enum.join(", ")

    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required fields: #{missing}"})
  end

  defp do_donate(conn, key, upload, context) do
    log_message("Server", "info", "Donation request, key=#{key}", context)

    with {:ok, _user} <- get_current_user(conn),
         {:ok, data} <- read_upload(upload),
         meta_data <- build_meta_data(conn, key, context),
         :ok <- check_rate_limit(:feldspar_data_donation, meta_data.remote_ip, byte_size(data)),
         {:ok, storage_endpoint} <- get_storage_endpoint(context),
         file_id <- Feldspar.DataDonationFolder.filename(context),
         {:ok, %{id: ^file_id}} <- Feldspar.DataDonationFolder.store(data, file_id),
         :ok <- schedule_delivery(storage_endpoint, file_id, meta_data) do
      log_message("Server", "info", "Donation stored, key=#{key}, file_id=#{file_id}", context)

      json(conn, %{status: "ok"})
    else
      {:error, :not_authenticated} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Not authenticated"})

      {:error, :file_read_error, reason} ->
        log_message("Server", "error", "Failed to read upload: #{inspect(reason)}", context)

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to read upload"})

      {:error, :rate_limited, reason} ->
        log_message("Server", "warn", "Rate limited: #{reason}", context)

        conn
        |> put_status(:too_many_requests)
        |> json(%{error: "Rate limited: #{reason}"})

      {:error, :no_storage_endpoint} ->
        log_message("Server", "error", "No storage endpoint configured", context)

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "No storage endpoint configured"})

      {:error, {:scheduling_failed, step, reason}} ->
        log_message(
          "Server",
          "error",
          "Scheduling failed at step=#{step}: #{inspect(reason)}",
          context
        )

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Scheduling failed"})

      {:error, reason} ->
        log_message("Server", "error", "Storage failed: #{inspect(reason)}", context)

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Storage failed"})
    end
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
      log_message("Client", level, message, context)
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

    if assignment_id && assignment_id != "" do
      with {:ok, assignment} <- get_assignment(assignment_id) do
        case Project.Public.get_storage_endpoint_by(assignment) do
          {:ok, endpoint} -> {:ok, endpoint}
          {:error, {:storage_endpoint, :not_available}} -> {:error, :no_storage_endpoint}
        end
      end
    else
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
    case Assignment.Public.get(assignment_id, Assignment.Model.preload_graph(:down)) do
      nil -> {:error, :assignment_not_found}
      assignment -> {:ok, assignment}
    end
  end

  defp parse_context(nil), do: {:error, :invalid_context}
  defp parse_context(""), do: {:error, :invalid_context}

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

  defp log_message(source, level, message, context) do
    formatted_context = format_log_context(context)
    base_message = "[Feldspar.#{source}] #{message}#{formatted_context}"

    case level do
      # Route client debug to info with [DEBUG] flag so it appears in production logs
      "debug" -> Logger.info("[DEBUG] #{base_message}")
      "info" -> Logger.info(base_message)
      "warn" -> Logger.warning(base_message)
      "error" -> Logger.error(base_message)
    end
  end

  defp format_log_context(context) when context == %{}, do: ""

  defp format_log_context(context) do
    formatted = Enum.map_join(context, ", ", fn {k, v} -> "#{k}=#{inspect(v)}" end)
    " [#{formatted}]"
  end
end
