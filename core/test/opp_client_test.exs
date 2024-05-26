defmodule BankingClientTest do
  use ExUnit.Case, async: true

  setup do
    client = OPPClient.new(plug: {Req.Test, OPPClient}, base_url: "http://example.com/test")
    {:ok, client: client}
  end

  describe "post /merchant" do
    test "creates and returns merchant", %{client: client} do
      response_json = %{
        "compliance" => %{
          "level" => 100,
          "overview_url" => Faker.Internet.url(),
          "requirements" => [],
          "status" => "verified"
        },
        "country" => "nld",
        "created" => 1_554_113_700,
        "name" => Faker.Person.name(),
        "object" => "merchant",
        "phone" => "31601234567",
        "status" => "pending",
        "type" => "consumer",
        "uid" => "{{merchant_uid}}",
        "updated" => 1_554_113_700
      }

      Req.Test.stub(OPPClient, fn conn ->
        assert %{method: "POST", request_path: "/test/merchants", req_headers: req_headers} = conn
        assert Enum.any?(req_headers, fn {header, _} -> header == "idempotency-key" end)

        Req.Test.json(conn, response_json)
      end)

      assert {:ok, ^response_json} =
               OPPClient.post(
                 client,
                 "/merchants",
                 idempotency_key: "test",
                 type: "consumer",
                 country: "nld",
                 emailaddress: "test@example.com",
                 notify_url: ""
               )
    end
  end

  describe "get /merchants_by_merchant_uuid" do
    test "returns merchant", %{client: client} do
      response_json = %{
        "compliance" => %{
          "level" => 100,
          "overview_url" => Faker.Internet.url(),
          "requirements" => [],
          "status" => "verified"
        },
        "country" => "nld",
        "created" => 1_554_113_700,
        "name" => Faker.Person.name(),
        "object" => "merchant",
        "phone" => "31601234567",
        "status" => "pending",
        "type" => "consumer",
        "uid" => "{{merchant_uid}}",
        "updated" => 1_554_113_700
      }

      Req.Test.stub(OPPClient, fn conn ->
        assert %{method: "GET", request_path: "/test/merchants/123"} = conn
        Req.Test.json(conn, response_json)
      end)

      assert {:ok, ^response_json} =
               OPPClient.get(client, "/merchants/{{merchant_uuid}}", merchant_uuid: "123")
    end
  end

  describe "post /transactions" do
    test "creates and returns transaction", %{client: client} do
      response_json = %{
        "amount" => 250,
        "completed" => nil,
        "created" => 1_613_741_183,
        "escrow" => nil,
        "fees" => %{},
        "has_checkout" => false,
        "merchant_uid" => "{{merchant_uid}}",
        "metadata" => [%{"key" => "external_id", "value" => "2015486"}],
        "notify_url" => "https://platform.example.com/notify/",
        "object" => "transaction",
        "order" => [],
        "payment_details" => [],
        "payment_flow" => "direct",
        "payment_method" => nil,
        "profile_uid" => "{{profile_uid}}",
        "redirect_url" =>
          "https://sandbox.onlinebetaalplatform.nl/nl/6bfa1c3e1d1d/betalen/verzendgegevens/{{transaction_uid}}?vc=db2242295ee6565a7b2c8b69632ff530",
        "refunds" => %{},
        "return_url" => "https://platform.example.com/return/",
        "status" => "created",
        "statuses" => [
          %{
            "created" => 1_613_741_183,
            "object" => "status",
            "status" => "created",
            "uid" => "sta_8b03f99bbd54",
            "updated" => 1_613_741_183
          }
        ],
        "uid" => "{{transaction_uid}}",
        "updated" => 1_613_741_183
      }

      Req.Test.stub(OPPClient, fn conn ->
        assert %{method: "POST", request_path: "/test/transactions", req_headers: req_headers} =
                 conn

        assert Enum.any?(req_headers, fn {header, _} -> header == "idempotency-key" end)

        Req.Test.json(conn, response_json)
      end)

      assert {:ok, ^response_json} =
               OPPClient.post(
                 client,
                 "/transactions",
                 idempotency_key: "test",
                 merchant_uid: Faker.UUID.v4(),
                 locale: "nl",
                 total_price: 10,
                 products: [
                   %{
                     name: Faker.Pokemon.name(),
                     quantity: 1,
                     price: 10
                   }
                 ],
                 return_url: Faker.Internet.url(),
                 notify_url: Faker.Internet.url()
               )
    end
  end

  describe "post /merchants/{{merchant_uid}}/withdrawals" do
    test "creates and returns withdrawal", %{client: client} do
      merchant_uid = Faker.UUID.v4()

      response_json = %{
        "amount" => -100,
        "completed" => nil,
        "created" => 1_651_220_718,
        "currency" => "EUR",
        "description" => "Withdrawal",
        "execution" => nil,
        "expected" => "next_day",
        "fees" => %{},
        "livemode" => false,
        "metadata" => [%{"key" => "external_id", "value" => "2015486"}],
        "notify_url" => "https://platform.example.com/notify/",
        "object" => "withdrawal",
        "receiver" => "self",
        "receiver_details" => %{
          "object" => "withdrawal_receiver",
          "receiver_account" => "NL53***********370",
          "receiver_bic" => "INGBNL2A",
          "receiver_iban" => "NL53***********370",
          "receiver_name" => "Hr E G H Küppers en/of MW M.J. Küppers-Veeneman",
          "receiver_sort_code" => nil,
          "receiver_type" => "bank"
        },
        "reference" => "withdrawal-ABC123",
        "status" => "pending",
        "status_reason" => nil,
        "statuses" => [
          %{
            "created" => 1_651_220_718,
            "object" => "status",
            "status" => "created",
            "uid" => "wds_03a387e14549",
            "updated" => 1_651_220_718
          },
          %{
            "created" => 1_651_220_718,
            "object" => "status",
            "status" => "pending",
            "uid" => "wds_5fdd7c529fc5",
            "updated" => 1_651_220_718
          }
        ],
        "uid" => "{{withdrawal_uid}}",
        "updated" => 1_651_220_718
      }

      Req.Test.stub(OPPClient, fn conn ->
        expected_path = "/test/merchants/#{merchant_uid}/withdrawals"
        assert %{method: "POST", request_path: ^expected_path, req_headers: req_headers} = conn

        assert Enum.any?(req_headers, fn {header, _} -> header == "idempotency-key" end)

        Req.Test.json(conn, response_json)
      end)

      assert {:ok, ^response_json} =
               OPPClient.post(
                 client,
                 "/merchants/{{merchant_uid}}/withdrawals",
                 idempotency_key: "test",
                 merchant_uid: merchant_uid,
                 amount: 11,
                 notify_url: Faker.Internet.url(),
                 description: Faker.Lorem.sentence()
               )
    end
  end

  describe "post /charges" do
    test "creates and returns charge", %{client: client} do
      merchant_uid = Faker.UUID.v4()

      response_json = %{
        "amount" => 100,
        "created" => 1_637_674_410,
        "currency" => "EUR",
        "description" => "Moving funds",
        "from_merchant_uid" => "{{merchant_uid}}",
        "from_profile_uid" => "{{profile_uid}}",
        "metadata" => [],
        "object" => "charge",
        "settled" => 1_637_674_410,
        "to_merchant_uid" => "{{merchant_uid}}",
        "to_profile_uid" => "{{profile_uid}}",
        "type" => "balance",
        "uid" => "{{charge_uid}}",
        "updated" => 1_637_674_410
      }

      Req.Test.stub(OPPClient, fn conn ->
        expected_path = "/test/charges"
        assert %{method: "POST", request_path: ^expected_path, req_headers: req_headers} = conn

        assert Enum.any?(req_headers, fn {header, _} -> header == "idempotency-key" end)

        Req.Test.json(conn, response_json)
      end)

      assert {:ok, ^response_json} =
               OPPClient.post(
                 client,
                 "/charges",
                 idempotency_key: "test",
                 type: "balance",
                 amount: 12,
                 to_owner_uid: Faker.UUID.v4(),
                 from_owner_uid: Faker.UUID.v4()
               )
    end
  end
end
