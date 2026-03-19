defmodule Systems.Payment.Provider.OPP.WebhookTest do
  use ExUnit.Case, async: true

  @moduletag :capture_log

  alias Systems.Payment.Provider.OPP.Webhook
  alias Systems.Payment.Error

  @secret "test_notification_secret"
  @host "localhost"
  @date "Mon, 09 Mar 2026 12-00-00 GMT"

  setup do
    Application.put_env(:core, :payment,
      base_url: "https://api-sandbox.onlinebetaalplatform.nl/v1",
      api_key: "",
      notification_secret: @secret
    )

    :ok
  end

  defp build_signed_conn(body) do
    digest = "SHA-256=" <> (:crypto.hash(:sha256, body) |> Base.encode64())

    signing_string =
      "(request-target): post #{"/webhook"}\nhost: #{@host}\ndate: #{@date}\ndigest: #{digest}"

    signature = :crypto.mac(:hmac, :sha256, @secret, signing_string) |> Base.encode64()

    signature_header =
      "keyId=\"test\",algorithm=\"hmac-sha256\",headers=\"(request-target) host date digest\",signature=\"#{signature}\""

    conn = Plug.Test.conn(:post, "/webhook", body)

    %{
      conn
      | assigns: Map.put(conn.assigns, :raw_body, body),
        req_headers: [
          {"signature", signature_header},
          {"digest", digest},
          {"host", @host},
          {"date", @date}
        ]
    }
  end

  defp valid_event_body do
    Jason.encode!(%{
      "uid" => "notif_123",
      "type" => "merchant.status_changed",
      "object_uid" => "merchant_456",
      "object_type" => "merchant",
      "object_url" => "https://api.example.com/v1/merchants/merchant_456"
    })
  end

  describe "verify_and_parse/1 valid requests" do
    test "accepts webhook with correct signature" do
      body = valid_event_body()
      conn = build_signed_conn(body)

      assert {:ok, event} = Webhook.verify_and_parse(conn)
      assert event.uid == "notif_123"
      assert event.type == "merchant.status_changed"
      assert event.object_uid == "merchant_456"
      assert event.object_type == "merchant"
    end

    test "parses optional parent fields" do
      body =
        Jason.encode!(%{
          "uid" => "notif_1",
          "type" => "transaction.completed",
          "object_uid" => "tx_1",
          "object_type" => "transaction",
          "object_url" => "https://api.example.com/v1/transactions/tx_1",
          "parent_uid" => "merchant_1",
          "parent_type" => "merchant"
        })

      conn = build_signed_conn(body)

      assert {:ok, event} = Webhook.verify_and_parse(conn)
      assert event.parent_uid == "merchant_1"
      assert event.parent_type == "merchant"
    end
  end

  describe "verify_and_parse/1 signature verification" do
    test "rejects invalid signature" do
      body = valid_event_body()
      digest = "SHA-256=" <> (:crypto.hash(:sha256, body) |> Base.encode64())

      signature_header =
        "keyId=\"test\",algorithm=\"hmac-sha256\",headers=\"(request-target) host date digest\",signature=\"invalidsig\""

      conn = Plug.Test.conn(:post, "/webhook", body)

      conn = %{
        conn
        | assigns: Map.put(conn.assigns, :raw_body, body),
          req_headers: [
            {"signature", signature_header},
            {"digest", digest},
            {"host", @host},
            {"date", @date}
          ]
      }

      assert {:error, %Error{code: :invalid_signature}} = Webhook.verify_and_parse(conn)
    end

    test "rejects tampered body" do
      original_body = valid_event_body()
      tampered_body = Jason.encode!(%{"uid" => "n1", "type" => "hacked", "object_uid" => "o1"})

      conn = build_signed_conn(original_body)
      conn = %{conn | assigns: Map.put(conn.assigns, :raw_body, tampered_body)}

      assert {:error, %Error{code: :invalid_digest}} = Webhook.verify_and_parse(conn)
    end

    test "rejects missing signature header" do
      body = valid_event_body()
      digest = "SHA-256=" <> (:crypto.hash(:sha256, body) |> Base.encode64())

      conn = Plug.Test.conn(:post, "/webhook", body)

      conn = %{
        conn
        | assigns: Map.put(conn.assigns, :raw_body, body),
          req_headers: [{"digest", digest}]
      }

      assert {:error, %Error{code: :missing_header}} = Webhook.verify_and_parse(conn)
    end
  end

  describe "verify_and_parse/1 body parsing" do
    test "rejects missing body" do
      conn = Plug.Test.conn(:post, "/webhook", "")

      assert {:error, %Error{code: :missing_body}} = Webhook.verify_and_parse(conn)
    end

    test "rejects invalid JSON" do
      body = "not json"
      conn = build_signed_conn(body)

      assert {:error, %Error{code: :invalid_json}} = Webhook.verify_and_parse(conn)
    end

    test "rejects missing required event fields" do
      body = Jason.encode!(%{"foo" => "bar"})
      conn = build_signed_conn(body)

      assert {:error, %Error{code: :invalid_event}} = Webhook.verify_and_parse(conn)
    end
  end
end
