defmodule Systems.Payment.Provider.OPP.Webhook do
  @behaviour Systems.Payment.Webhook

  @signature_regex ~r/(\w+)="([^"]*)"/

  # OPP resource names used both to classify an event as KYC and to resolve its
  # owning merchant — kept in one place so the wire vocabulary isn't duplicated.
  @merchant_type "merchant"
  @bank_account_type "bank_account"
  @kyc_object_types [@merchant_type, @bank_account_type]

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
      {:ok, %{"uid" => _uid, "type" => type, "object_uid" => object_uid} = data} ->
        {:ok, classify(type, object_uid, data)}

      {:ok, _} ->
        {:error, %Error{code: :invalid_event, message: "Missing required event fields"}}

      {:error, _} ->
        {:error, %Error{code: :invalid_json, message: "Invalid JSON body"}}
    end
  end

  # Translate OPP's wire vocabulary into the provider-agnostic event the domain
  # routes on. OPP prefixes the event `type` with the owning resource (e.g.
  # "merchant.withdrawal.status.changed"), so the authoritative `object_type` is
  # settled first; only KYC events, then the bare `type` string, are consulted
  # after.
  defp classify(type, object_uid, data) do
    object_type = Map.get(data, "object_type", "")

    cond do
      object_type == "withdrawal" -> event(:withdrawal, object_uid, type)
      object_type == "transaction" -> event(:transaction, object_uid, type)
      kyc?(type, object_type) -> classify_kyc(type, object_uid, data)
      status_changed(type) == :transaction -> event(:transaction, object_uid, type)
      status_changed(type) == :withdrawal -> event(:withdrawal, object_uid, type)
      true -> event(:ignored, object_uid, type)
    end
  end

  # `merchant_uid` is only set for :kyc events; every other category leaves it nil.
  defp event(category, object_uid, raw_type, merchant_uid \\ nil) do
    %{category: category, object_uid: object_uid, merchant_uid: merchant_uid, raw_type: raw_type}
  end

  # OPP sends both dotted and underscore variants of the status-change type.
  defp status_changed("transaction.status.changed"), do: :transaction
  defp status_changed("transaction.status_changed"), do: :transaction
  defp status_changed("withdrawal.status.changed"), do: :withdrawal
  defp status_changed("withdrawal.status_changed"), do: :withdrawal
  defp status_changed(_type), do: nil

  # OPP's exact bank-account/merchant event-type strings vary; match on either the
  # object_type or a type prefix so a KYC status change is never missed.
  defp kyc?(type, object_type) do
    object_type in @kyc_object_types or
      String.starts_with?(type, @bank_account_type) or
      String.starts_with?(type, @merchant_type)
  end

  # Resolve the owning merchant so the domain can refresh the participant's badge.
  # When it can't be resolved the event is unroutable — log the OPP-specific
  # identifiers here (they never reach the controller) and drop it to `:ignored`.
  defp classify_kyc(type, object_uid, data) do
    case resolve_merchant_uid(type, object_uid, data) do
      merchant_uid when is_binary(merchant_uid) ->
        event(:kyc, object_uid, type, merchant_uid)

      nil ->
        log_unresolvable_kyc(type, object_uid, data)
        event(:ignored, object_uid, type)
    end
  end

  # A merchant event is itself the merchant; a bank-account event's owning merchant
  # is its parent; OPP's type-prefix carries ownership when object_type isn't set.
  defp resolve_merchant_uid(type, object_uid, data) do
    cond do
      Map.get(data, "object_type") == @merchant_type ->
        object_uid

      Map.get(data, "parent_type") == @merchant_type and is_binary(Map.get(data, "parent_uid")) ->
        Map.get(data, "parent_uid")

      String.starts_with?(type, @merchant_type) ->
        object_uid

      true ->
        nil
    end
  end

  defp log_unresolvable_kyc(type, object_uid, data) do
    Logger.error(
      "[OPP.Webhook] KYC event missing merchant reference — badge will not refresh. " <>
        "type=#{inspect(type)} " <>
        "object_type=#{inspect(Map.get(data, "object_type"))} " <>
        "object_uid=#{inspect(object_uid)} " <>
        "parent_type=#{inspect(Map.get(data, "parent_type"))} " <>
        "parent_uid=#{inspect(Map.get(data, "parent_uid"))}"
    )
  end

  defp notification_secret do
    Application.fetch_env!(:core, Systems.Payment.Provider.OPP)
    |> Keyword.fetch!(:notification_secret)
  end
end
