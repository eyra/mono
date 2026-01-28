defmodule Systems.Feldspar.DataDonationController do
  @moduledoc """
  HTTP endpoint for data donation uploads.

  Handles large data donations via HTTP POST instead of WebSocket, which allows for
  better concurrent upload handling, avoids WebSocket message size limitations, and
  ensures delivery is scheduled even if the user closes the tab.
  """
  use CoreWeb, {:controller, [formats: [:json]]}

  require Logger

  alias Systems.Assignment
  alias Systems.Feldspar
  alias Systems.Project
  alias Systems.Rate
  alias Systems.Storage

  @rate_limit_service :feldspar_data_donation

  @doc """
  Accepts a data donation, stores it as a file, and schedules delivery.

  Expects multipart/form-data with:
  - key: Identifier key for the data
  - context: JSON string containing assignment_id, task, participant, group, panel_info
  - data: File upload containing the data

  Returns:
  - 200 with {status: "ok"} on success
  - 401 if user not authenticated
  - 422 if storage/delivery fails
  - 429 if rate limited
  """
  def create(conn, %{"key" => key, "data" => %Plug.Upload{} = upload, "context" => context}) do
    Logger.info("[Feldspar.DataDonationController] Donation request for key=#{key}")

    with {:ok, context} <- parse_context(context),
         {:ok, _user} <- get_current_user(conn),
         {:ok, data} <- read_upload(upload),
         meta_data <- build_meta_data(conn, key, context),
         :ok <- check_rate_limit(meta_data.remote_ip, byte_size(data)),
         {:ok, storage_endpoint} <- get_storage_endpoint(context),
         file_id <- Feldspar.DataDonationFolder.filename(context),
         {:ok, %{id: ^file_id}} <- Feldspar.DataDonationFolder.store(data, file_id),
         :ok <- schedule_delivery(storage_endpoint, file_id, meta_data) do
      Logger.info(
        "[Feldspar.DataDonationController] Donation stored and delivery scheduled, key=#{key}, file_id=#{file_id}"
      )

      json(conn, %{status: "ok"})
    else
      {:error, :not_authenticated} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Not authenticated"})

      {:error, :file_read_error, reason} ->
        Logger.error(
          "[Feldspar.DataDonationController] Failed to read upload: #{inspect(reason)}"
        )

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to read upload"})

      {:error, :rate_limited, reason} ->
        Logger.warning("[Feldspar.DataDonationController] Rate limited: #{reason}")

        conn
        |> put_status(:too_many_requests)
        |> json(%{error: "Rate limited: #{reason}"})

      {:error, :invalid_context} ->
        Logger.error("[Feldspar.DataDonationController] Missing or invalid context")

        conn
        |> put_status(:bad_request)
        |> json(%{error: "Missing or invalid context"})

      {:error, :no_storage_endpoint} ->
        Logger.error("[Feldspar.DataDonationController] No storage endpoint configured")

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "No storage endpoint configured"})

      {:error, reason} ->
        Logger.error("[Feldspar.DataDonationController] Storage failed: #{inspect(reason)}")

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Storage failed"})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required fields: key, data"})
  end

  defp get_current_user(conn) do
    case conn.assigns[:current_user] do
      nil -> {:error, :not_authenticated}
      user -> {:ok, user}
    end
  end

  defp read_upload(%Plug.Upload{path: path}) do
    case File.read(path) do
      {:ok, data} -> {:ok, data}
      {:error, reason} -> {:error, :file_read_error, reason}
    end
  end

  defp check_rate_limit(remote_ip, packet_size) do
    Rate.Public.request_permission(@rate_limit_service, remote_ip, packet_size)
    :ok
  rescue
    e in Rate.Public.RateLimitError ->
      {:error, :rate_limited, e.message}
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
      error -> error
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
  defp parse_context("{}"), do: {:error, :invalid_context}

  defp parse_context(json) when is_binary(json) do
    case Jason.decode(json) do
      {:ok, map} when map == %{} -> {:error, :invalid_context}
      {:ok, map} -> {:ok, map}
      {:error, _} -> {:error, :invalid_context}
    end
  end

  defp build_meta_data(conn, key, context) do
    remote_ip =
      conn.remote_ip
      |> :inet.ntoa()
      |> to_string()

    %{
      remote_ip: remote_ip,
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
end
