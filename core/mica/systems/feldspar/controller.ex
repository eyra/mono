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
  @preview_participant "preview"
  @max_id 9_223_372_036_854_775_807

  # Context keys copied to the Logger metadata; any other key only shows up in the message.
  @context_metadata_keys %{
    "assignment_id" => :feldspar_assignment_id,
    "task" => :feldspar_task,
    "participant" => :feldspar_participant,
    "group" => :feldspar_group,
    "key" => :feldspar_key,
    "dataSize" => :feldspar_dataSize,
    "status" => :feldspar_status
  }

  # ============================================================================
  # Donate endpoint
  # ============================================================================

  @doc """
  Accepts a data donation, stores it as a file, and schedules delivery.

  Expects multipart/form-data with:
  - key: Identifier key for the data
  - context: JSON string containing assignment_id, task, group. The participant is
    taken from the user's own participation, not from the context.
  - data: File upload containing the data

  Returns:
  - 200 with {status: "ok"} on success
  - 400 if missing required fields (key, data, context), invalid context or assignment_id,
    or a control character (CR, LF, NUL, ...) in the key, task or group
  - 401 if user not authenticated
  - 403 if user is not a participant or tester of the assignment
  - 422 if storage/delivery fails
  - 429 if rate limited
  """
  def donate(conn, %{"key" => key, "data" => %Plug.Upload{} = upload, "context" => context_json}) do
    with {:ok, context} <- parse_context(context_json),
         :ok <- validate_identifier(key, context) do
      do_donate(conn, key, upload, context)
    else
      {:error, :invalid_context} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Missing or invalid context"})

      {:error, :invalid_identifier} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid key or context"})
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
    # The participant comes from the server once the user is known, never from the client
    context = Map.drop(context, ["participant", "panel_info"])
    telemetry_metadata = telemetry_metadata(context)
    start_time = emit_telemetry_start([:feldspar, :donate], telemetry_metadata)

    with {:ok, user} <- get_current_user(conn),
         log_message("Server", "info", "Donation request, key=#{key}", context),
         {:ok, data} <- read_upload(upload),
         :ok <- check_rate_limit(:feldspar_data_donation, get_remote_ip(conn), byte_size(data)),
         {:ok, %{id: assignment_id} = assignment} <- get_assignment(context),
         {:ok, participant} <- get_participant(conn, assignment, user),
         {:ok, storage_endpoint} <- get_storage_endpoint(assignment),
         context <-
           Map.merge(context, %{"assignment_id" => assignment_id, "participant" => participant}),
         meta_data <- build_meta_data(conn, key, context),
         file_id <- Feldspar.DataDonationFolder.filename(context),
         {:ok, %{id: ^file_id}} <- Feldspar.DataDonationFolder.store(data, file_id),
         :ok <- schedule_delivery(storage_endpoint, file_id, meta_data) do
      measurements = %{file_size_bytes: byte_size(data)}

      emit_telemetry_stop(
        [:feldspar, :donate],
        start_time,
        measurements,
        telemetry_metadata(context)
      )

      log_message("Server", "info", "Donation stored, key=#{key}, file_id=#{file_id}", context)

      json(conn, %{status: "ok"})
    else
      {:error, :not_authenticated} ->
        emit_telemetry_exception(
          [:feldspar, :donate],
          start_time,
          :not_authenticated,
          telemetry_metadata
        )

        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Not authenticated"})

      {:error, :file_read_error, reason} ->
        emit_telemetry_exception(
          [:feldspar, :donate],
          start_time,
          :file_read_error,
          telemetry_metadata
        )

        log_message("Server", "error", "Failed to read upload: #{inspect(reason)}", context)

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to read upload"})

      {:error, :rate_limited, reason} ->
        emit_telemetry_exception(
          [:feldspar, :donate],
          start_time,
          :rate_limited,
          telemetry_metadata
        )

        :telemetry.execute([:feldspar, :donate, :rate_limited], %{count: 1}, telemetry_metadata)
        log_message("Server", "warn", "Rate limited: #{reason}", context)

        conn
        |> put_status(:too_many_requests)
        |> json(%{error: "Rate limited: #{reason}"})

      {:error, :not_participant} ->
        emit_telemetry_exception(
          [:feldspar, :donate],
          start_time,
          :not_participant,
          telemetry_metadata
        )

        log_message("Server", "warn", "Donation refused: not a participant", context)

        conn
        |> put_status(:forbidden)
        |> json(%{error: "Not a participant of this assignment"})

      {:error, :missing_assignment} ->
        emit_telemetry_exception(
          [:feldspar, :donate],
          start_time,
          :missing_assignment,
          telemetry_metadata
        )

        conn
        |> put_status(:bad_request)
        |> json(%{error: "Missing or invalid assignment_id"})

      {:error, :no_storage_endpoint} ->
        emit_telemetry_exception(
          [:feldspar, :donate],
          start_time,
          :no_storage_endpoint,
          telemetry_metadata
        )

        log_message("Server", "error", "No storage endpoint configured", context)

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "No storage endpoint configured"})

      {:error, {:scheduling_failed, step, reason}} ->
        emit_telemetry_exception(
          [:feldspar, :donate],
          start_time,
          :scheduling_failed,
          telemetry_metadata
        )

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
        emit_telemetry_exception([:feldspar, :donate], start_time, reason, telemetry_metadata)
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
    context = log_context(params["context"])
    telemetry_metadata = telemetry_metadata(context) |> Map.put(:level, telemetry_value(level))
    start_time = emit_telemetry_start([:feldspar, :log], telemetry_metadata)

    with {:ok, _user} <- get_current_user(conn),
         :ok <- validate_log_level(level),
         :ok <- check_rate_limit(:feldspar_log, get_remote_ip(conn), 1) do
      log_message("Client", level, message, context)
      emit_telemetry_stop([:feldspar, :log], start_time, %{}, telemetry_metadata)
      json(conn, %{status: "ok"})
    else
      {:error, :not_authenticated} ->
        emit_telemetry_exception(
          [:feldspar, :log],
          start_time,
          :not_authenticated,
          telemetry_metadata
        )

        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Not authenticated"})

      {:error, :invalid_level} ->
        emit_telemetry_exception(
          [:feldspar, :log],
          start_time,
          :invalid_level,
          telemetry_metadata
        )

        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid level. Must be one of: #{Enum.join(@valid_log_levels, ", ")}"})

      {:error, :rate_limited, reason} ->
        emit_telemetry_exception([:feldspar, :log], start_time, :rate_limited, telemetry_metadata)
        :telemetry.execute([:feldspar, :log, :rate_limited], %{count: 1}, telemetry_metadata)

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

  defp get_storage_endpoint(assignment) do
    case Project.Public.get_storage_endpoint_by(assignment) do
      {:ok, endpoint} -> {:ok, endpoint}
      {:error, {:storage_endpoint, :not_available}} -> {:error, :no_storage_endpoint}
    end
  end

  # Only crew members (participants and testers) donate to an assignment, under the id
  # the assignment knows them by. A tester previewing it donates as "preview".
  defp get_participant(conn, assignment, user) do
    case Assignment.Public.participant_identifier(assignment, user) do
      {:ok, participant} ->
        if preview?(conn, assignment, user),
          do: {:ok, @preview_participant},
          else: {:ok, participant}

      :error ->
        {:error, :not_participant}
    end
  end

  defp preview?(conn, assignment, user) do
    match?(%{participant: @preview_participant}, get_session(conn, :panel_info)) and
      Assignment.Public.tester?(assignment, user)
  end

  defp schedule_delivery(storage_endpoint, file_id, meta_data) do
    case Storage.Public.deliver_file(storage_endpoint, file_id, meta_data) do
      {:ok, _} -> :ok
      {:error, step, reason, _} -> {:error, {:scheduling_failed, step, reason}}
    end
  end

  defp get_assignment(%{"assignment_id" => assignment_id}) do
    with {:ok, id} <- parse_id(assignment_id) do
      case Assignment.Public.get(id, Assignment.Model.preload_graph(:down)) do
        nil -> {:error, :not_participant}
        assignment -> {:ok, assignment}
      end
    end
  end

  defp get_assignment(_context), do: {:error, :missing_assignment}

  defp parse_id(id) when is_integer(id) and id > 0 and id <= @max_id, do: {:ok, id}

  defp parse_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {int, ""} -> parse_id(int)
      _ -> {:error, :missing_assignment}
    end
  end

  defp parse_id(_id), do: {:error, :missing_assignment}

  defp parse_context(nil), do: {:error, :invalid_context}
  defp parse_context(""), do: {:error, :invalid_context}

  defp parse_context(json) when is_binary(json) do
    case Jason.decode(json) do
      {:ok, %{} = map} when map_size(map) > 0 -> {:ok, map}
      _ -> {:error, :invalid_context}
    end
  end

  # Task, group and key reach the storage file name as the client sent them.
  defp validate_identifier(key, context) do
    client_values = [[:task, context["task"]], [:source, context["group"]], [:key, key]]

    if Storage.Filename.valid_identifier?(client_values),
      do: :ok,
      else: {:error, :invalid_identifier}
  end

  defp build_meta_data(conn, key, context) do
    %{
      remote_ip: get_remote_ip(conn),
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

  defp log_context(%{} = context), do: context
  defp log_context(_), do: %{}

  defp validate_log_level(level) when level in @valid_log_levels, do: :ok
  defp validate_log_level(_), do: {:error, :invalid_level}

  defp log_message(source, level, message, context) do
    set_appsignal_attributes(context)
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

  defp set_appsignal_attributes(context) when context == %{}, do: :ok

  defp set_appsignal_attributes(context) do
    metadata =
      for {key, value} <- context, Map.has_key?(@context_metadata_keys, key) do
        {Map.fetch!(@context_metadata_keys, key), metadata_value(value)}
      end

    Logger.metadata(metadata)
  end

  defp metadata_value(value) when is_binary(value), do: value
  defp metadata_value(value) when is_number(value) or is_atom(value), do: to_string(value)
  defp metadata_value(value), do: inspect(value)

  defp format_log_context(context) when context == %{}, do: ""

  defp format_log_context(context) do
    formatted = Enum.map_join(context, ", ", fn {k, v} -> "#{k}=#{inspect(v)}" end)
    " [#{formatted}]"
  end

  # ============================================================================
  # Telemetry helpers
  # ============================================================================

  defp telemetry_metadata(context) do
    %{
      assignment_id: telemetry_value(context["assignment_id"]),
      participant: telemetry_value(context["participant"]),
      group: telemetry_value(context["group"]),
      task: telemetry_value(context["task"])
    }
  end

  # Telemetry handlers turn metadata values into tags with to_string/1
  defp telemetry_value(nil), do: nil
  defp telemetry_value(value), do: metadata_value(value)

  defp emit_telemetry_start(event_prefix, metadata) do
    start_time = System.monotonic_time()
    :telemetry.execute(event_prefix ++ [:start], %{system_time: System.system_time()}, metadata)
    start_time
  end

  defp emit_telemetry_stop(event_prefix, start_time, extra_measurements, metadata) do
    duration = System.monotonic_time() - start_time

    :telemetry.execute(
      event_prefix ++ [:stop],
      Map.merge(%{duration: duration}, extra_measurements),
      metadata
    )
  end

  defp emit_telemetry_exception(event_prefix, start_time, reason, metadata) do
    duration = System.monotonic_time() - start_time

    :telemetry.execute(
      event_prefix ++ [:exception],
      %{duration: duration},
      Map.put(metadata, :reason, reason)
    )
  end
end
