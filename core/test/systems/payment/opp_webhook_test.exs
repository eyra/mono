defmodule Systems.Payment.Provider.OPP.WebhookTest do
  use ExUnit.Case, async: true

  @moduletag :capture_log

  alias Systems.Payment.Provider.OPP.Webhook
  alias Systems.Payment.Error

  @secret Faker.String.base64(32)
  @host Faker.Internet.domain_name()
  @date "Mon, 09 Mar 2026 12-00-00 GMT"

  setup do
    original = Application.get_env(:core, Systems.Payment.Provider.OPP, [])

    Application.put_env(
      :core,
      Systems.Payment.Provider.OPP,
      Keyword.put(original, :notification_secret, @secret)
    )

    on_exit(fn -> Application.put_env(:core, Systems.Payment.Provider.OPP, original) end)
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

  describe "verify_and_parse/1 classifies OPP events into the agnostic shape" do
    test "a merchant event becomes a :kyc event owned by the merchant itself" do
      body = valid_event_body()
      conn = build_signed_conn(body)

      assert {:ok, event} = Webhook.verify_and_parse(conn)
      assert event.category == :kyc
      assert event.merchant_uid == "merchant_456"
      assert event.raw_type == "merchant.status_changed"
    end

    test "a bank_account event resolves its owning merchant from the parent fields" do
      body =
        Jason.encode!(%{
          "uid" => "notif_1",
          "type" => "bank_account.status.changed",
          "object_uid" => "ba_1",
          "object_type" => "bank_account",
          "object_url" => "https://api.example.com/v1/bank_accounts/ba_1",
          "parent_uid" => "merchant_1",
          "parent_type" => "merchant"
        })

      conn = build_signed_conn(body)

      assert {:ok, event} = Webhook.verify_and_parse(conn)
      assert event.category == :kyc
      assert event.merchant_uid == "merchant_1"
    end

    test "a merchant-prefixed withdrawal event becomes a :withdrawal, not :kyc" do
      body =
        Jason.encode!(%{
          "uid" => "notif_2",
          "type" => "merchant.withdrawal.status.changed",
          "object_uid" => "w_1",
          "object_type" => "withdrawal",
          "object_url" => "https://api.example.com/v1/withdrawals/w_1"
        })

      conn = build_signed_conn(body)

      assert {:ok, event} = Webhook.verify_and_parse(conn)
      assert event.category == :withdrawal
      assert event.object_uid == "w_1"
    end

    test "falls back to the bare type string when object_type is absent (transaction)" do
      body =
        Jason.encode!(%{
          "uid" => "notif_3",
          "type" => "transaction.status.changed",
          "object_uid" => "tx_9"
        })

      conn = build_signed_conn(body)

      assert {:ok, event} = Webhook.verify_and_parse(conn)
      assert event.category == :transaction
      assert event.object_uid == "tx_9"
    end

    test "falls back on the underscore type variant when object_type is absent (withdrawal)" do
      body =
        Jason.encode!(%{
          "uid" => "notif_4",
          "type" => "withdrawal.status_changed",
          "object_uid" => "w_9"
        })

      conn = build_signed_conn(body)

      assert {:ok, event} = Webhook.verify_and_parse(conn)
      assert event.category == :withdrawal
      assert event.object_uid == "w_9"
    end

    test "an unrecognised event is classified :ignored" do
      body =
        Jason.encode!(%{
          "uid" => "notif_5",
          "type" => "some.other.event",
          "object_uid" => "x_9"
        })

      conn = build_signed_conn(body)

      assert {:ok, event} = Webhook.verify_and_parse(conn)
      assert event.category == :ignored
      assert event.raw_type == "some.other.event"
    end

    test "a KYC event with no resolvable merchant stays :kyc with a nil merchant_uid" do
      body =
        Jason.encode!(%{
          "uid" => "notif_orphan",
          "type" => "bank_account.status.changed",
          "object_uid" => "ba_orphan",
          "object_type" => "bank_account"
        })

      conn = build_signed_conn(body)

      assert {:ok, event} = Webhook.verify_and_parse(conn)
      assert event.category == :kyc
      assert event.merchant_uid == nil
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
