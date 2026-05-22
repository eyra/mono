defmodule Systems.Payment.Provider.OPP.Webhook do
  @behaviour Systems.Payment.Webhook

  @signature_regex ~r/(\w+)="([^"]*)"/

  require Logger

  alias Systems.Payment.Error

  @impl true
  def verify_and_parse(conn) do
    with {:ok, body} <- read_body(conn),
         :ok <- verify_signature(conn, body) do
      parse_event(body)
    end
  end

  defp read_body(conn) do
    case Map.get(conn.assigns, :raw_body) do
      nil -> {:error, %Error{code: :missing_body, message: "Missing request body"}}
      body -> {:ok, body}
    end
  end

  defp verify_signature(conn, body) do
    if Application.get_env(:core, :skip_webhook_verification, false) do
      Logger.warning("[OPP.Webhook] Skipping signature verification (dev mode)")
      :ok
    else
      with {:ok, signature_header} <- get_header(conn, "signature"),
           {:ok, digest_header} <- get_header(conn, "digest"),
           :ok <- verify_digest(digest_header, body),
           {:ok, params} <- parse_signature_header(signature_header) do
        verify_hmac(conn, params)
      end
    end
  end

  defp get_header(conn, name) do
    case Plug.Conn.get_req_header(conn, name) do
      [value | _] -> {:ok, value}
      [] -> {:error, %Error{code: :missing_header, message: "Missing #{name} header"}}
    end
  end

  defp verify_digest(digest_header, body) do
    case String.split(digest_header, "=", parts: 2) do
      ["SHA-256", expected_digest] ->
        actual_digest = :crypto.hash(:sha256, body) |> Base.encode64()

        if Plug.Crypto.secure_compare(actual_digest, expected_digest) do
          :ok
        else
          {:error, %Error{code: :invalid_digest, message: "Digest mismatch"}}
        end

      _ ->
        {:error, %Error{code: :invalid_digest, message: "Unsupported digest algorithm"}}
    end
  end

  defp parse_signature_header(header) do
    params =
      Regex.scan(@signature_regex, header)
      |> Enum.into(%{}, fn [_, key, value] -> {key, value} end)

    if Map.has_key?(params, "signature") do
      {:ok, params}
    else
      {:error, %Error{code: :invalid_signature, message: "Missing signature in header"}}
    end
  end

  defp verify_hmac(conn, %{"signature" => signature, "headers" => signed_headers}) do
    secret = notification_secret()
    signing_string = build_signing_string(conn, signed_headers)

    expected_signature =
      :crypto.mac(:hmac, :sha256, secret, signing_string)
      |> Base.encode64()

    if Plug.Crypto.secure_compare(expected_signature, signature) do
      :ok
    else
      {:error, %Error{code: :invalid_signature, message: "Signature verification failed"}}
    end
  end

  defp verify_hmac(_conn, _params) do
    {:error, %Error{code: :invalid_signature, message: "Missing headers field in signature"}}
  end

  defp build_signing_string(conn, signed_headers_str) do
    signed_headers_str
    |> String.split(" ")
    |> Enum.map_join("\n", fn
      "(request-target)" ->
        method = conn.method |> String.downcase()
        path = conn.request_path
        "(request-target): #{method} #{path}"

      header_name ->
        value =
          conn
          |> Plug.Conn.get_req_header(header_name)
          |> List.first("")

        "#{header_name}: #{value}"
    end)
  end

  defp parse_event(body) do
    case Jason.decode(body) do
      {:ok, %{"uid" => uid, "type" => type, "object_uid" => object_uid} = data} ->
        event = %{
          uid: uid,
          type: type,
          object_uid: object_uid,
          object_type: Map.get(data, "object_type", ""),
          object_url: Map.get(data, "object_url", ""),
          parent_uid: Map.get(data, "parent_uid"),
          parent_type: Map.get(data, "parent_type")
        }

        {:ok, event}

      {:ok, _} ->
        {:error, %Error{code: :invalid_event, message: "Missing required event fields"}}

      {:error, _} ->
        {:error, %Error{code: :invalid_json, message: "Invalid JSON body"}}
    end
  end

  defp notification_secret do
    Application.fetch_env!(:core, Systems.Payment.Provider.OPP)
    |> Keyword.fetch!(:notification_secret)
  end
end
