defmodule Bunq.APITest do
  use ExUnit.Case
  import Mox
  alias Bunq.{API, Conn}

  setup_all do
    private_key = API.generate_key()

    {:ok,
     private_key: private_key,
     conn: API.create_conn("https://test.sandbox.bunq.com/v1", private_key)}
  end

  describe "create_conn/2" do
    test "creates session" do
      assert %Bunq.Conn{} = API.create_conn(API.sandbox_endpoint(), API.generate_key())
    end
  end

  describe "create_sandbox_company/0" do
    test "returns a token", %{conn: conn} do
      Bunq.MockHTTP
      |> expect(:request!, fn :post,
                              "https://test.sandbox.bunq.com/v1/sandbox-user-company",
                              "",
                              [],
                              [recv_timeout: _] ->
        %{
          body:
            Jason.encode!(%{
              "Response" => [%{"ApiKey" => %{"api_key" => "a key"}}]
            })
        }
      end)

      %Bunq.Conn{api_key: "a key"} = API.create_sandbox_company(conn)
    end
  end

  #

  describe "create_installation/1" do
    test "configures installation token and server public key", %{conn: conn} do
      Bunq.MockHTTP
      |> expect(:request!, fn :post, "https://test.sandbox.bunq.com/v1/installation", _, [], [] ->
        %{
          body:
            Jason.encode!(%{
              "Response" => [
                %{"Token" => %{"token" => "the token"}},
                %{"ServerPublicKey" => %{"server_public_key" => "the server key"}},
                %{"Id" => %{"id" => 1234}}
              ]
            })
        }
      end)

      assert %Bunq.Conn{server_public_key: "the server key", installation_token: "the token"} =
               API.create_installation(conn)
    end
  end

  describe "register_device/2" do
    test "requires an installation to be configured", %{conn: conn} do
      assert_raise FunctionClauseError, fn -> API.register_device(conn) end
    end

    test "returns conn with device ID", %{conn: conn} do
      Bunq.MockHTTP
      |> expect(:request!, fn :post,
                              "https://test.sandbox.bunq.com/v1/device-server",
                              _,
                              [{"X-Bunq-Client-Authentication", "some token"}],
                              [] ->
        %{
          body:
            Jason.encode!(%{
              "Response" => [
                %{"Id" => %{"id" => 1234}}
              ]
            })
        }
      end)

      assert %Conn{device_id: device_id} =
               API.register_device(%{conn | api_key: "a key", installation_token: "some token"})

      assert is_integer(device_id)
    end
  end

  describe "start_session/1" do
    test "returns the session", %{conn: conn} do
      expect_signed_request(
        conn,
        :post,
        "/session-server",
        %{
          "Response" => [
            %{"UserCompany" => %{"id" => 543}},
            %{"Token" => %{"token" => "a session token"}},
            %{"Id" => %{"id" => 8}}
          ]
        }
      )

      assert %Bunq.Conn{session_token: "a session token"} =
               API.start_session(%{conn | api_key: "key", installation_token: "some token"})
    end
  end

  describe "list_accounts/1" do
    test "returns the session", %{conn: conn} do
      expect_request(conn, :get, "/user/12/monetary-account", %{
        "Response" => [
          %{
            "MonetaryAccountBank" => %{
              "id" => 789,
              "alias" => [
                %{"type" => "IBAN", "value" => "NLASD123", "name" => "An account"}
              ]
            }
          }
        ]
      })

      assert [
               %{
                 iban: %{
                   account: "NLASD123",
                   name: "An account"
                 },
                 id: 789
               }
             ] = API.list_accounts(%{conn | session_token: "a session token", company_id: 12})
    end
  end

  describe "list_payments/1" do
    test "returns payments", %{conn: conn} do
      expect_request(conn, :get, "/user/12/monetary-account/567/payment?count=200", %{
        "Pagination" => %{
          "future_url" =>
            "/v1/user/4130495/monetary-account/3962720/payment?count=200&newer_id=624878455",
          "newer_url" => nil,
          "older_url" => nil
        },
        "Response" => [
          %{
            "Payment" => %{
              "alias" => %{
                "country" => "NL",
                "display_name" => "Mega Corp",
                "iban" => "NL10BUNQ0000000001"
              },
              "amount" => %{"currency" => "EUR", "value" => "25.00"},
              "attachment" => [],
              "counterparty_alias" => %{
                "country" => "NL",
                "display_name" => "No Profitz",
                "iban" => "NL63ASNB0000000001"
              },
              "created" => "2021-11-19 12:07:37.191877",
              "description" => "Topup account",
              "id" => 222_222_333,
              "monetary_account_id" => 1_000_000,
              "sub_type" => "PAYMENT",
              "type" => "IDEAL",
              "updated" => "2021-11-19 12:07:37.191877"
            }
          }
        ]
      })

      assert {[payment], _cursor} =
               API.list_payments(%{
                 conn
                 | session_token: "a session token",
                   company_id: 12,
                   account_id: 567
               })

      assert payment == %{
               amount_in_cents: 2500,
               date: {:ok, ~N[2021-11-19 12:07:37.191877]},
               description: "Topup account",
               id: 222_222_333,
               payment_alias: %{
                 iban: "NL10BUNQ0000000001",
                 name: "Mega Corp"
               },
               payment_counterparty_alias: %{
                 iban: "NL63ASNB0000000001",
                 name: "No Profitz"
               }
             }
    end
  end

  describe "list_payments/2" do
    test "pagination", %{conn: conn} do
      expect_request(conn, :get, "/user/12/monetary-account/567/payment?count=200", %{
        "Pagination" => %{
          "future_url" => "/more-stuff",
          "newer_url" => nil,
          "older_url" => nil
        },
        "Response" => [
          %{
            "Payment" => %{
              "id" => 1,
              "alias" => %{
                "country" => "NL",
                "display_name" => "Mega Corp",
                "iban" => "NL10BUNQ0000000001"
              },
              "amount" => %{"currency" => "EUR", "value" => "25.00"},
              "attachment" => [],
              "counterparty_alias" => %{
                "country" => "NL",
                "display_name" => "No Profitz",
                "iban" => "NL63ASNB0000000001"
              },
              "created" => "2021-11-19 12:07:37.191877",
              "description" => "Topup account",
              "monetary_account_id" => 1_000_000,
              "sub_type" => "PAYMENT",
              "type" => "IDEAL",
              "updated" => "2021-11-19 12:07:37.191877"
            }
          }
        ]
      })

      assert {[%{id: 1}], cursor} =
               API.list_payments(%{
                 conn
                 | session_token: "a session token",
                   company_id: 12,
                   account_id: 567
               })

      assert %{has_more?: false} = cursor

      expect_request(conn, :get, "/more-stuff", %{
        "Pagination" => %{
          "future_url" => "/more-stuff",
          "newer_url" => "/even-more-stuff",
          "older_url" => nil
        },
        "Response" => []
      })

      assert {[], cursor} =
               API.list_payments(
                 %{conn | session_token: "a session token", company_id: 12},
                 cursor
               )

      expect_request(conn, :get, "/even-more-stuff", %{
        "Pagination" => %{
          "future_url" => "/more-stuff",
          "newer_url" => nil,
          "older_url" => nil
        },
        "Response" => [
          %{
            "Payment" => %{
              "id" => 2,
              "alias" => %{
                "country" => "NL",
                "display_name" => "Mega Corp",
                "iban" => "NL10BUNQ0000000001"
              },
              "amount" => %{"currency" => "EUR", "value" => "25.00"},
              "attachment" => [],
              "counterparty_alias" => %{
                "country" => "NL",
                "display_name" => "No Profitz",
                "iban" => "NL63ASNB0000000001"
              },
              "created" => "2021-11-19 12:07:37.191877",
              "description" => "Topup account",
              "monetary_account_id" => 1_000_000,
              "sub_type" => "PAYMENT",
              "type" => "IDEAL",
              "updated" => "2021-11-19 12:07:37.191877"
            }
          }
        ]
      })

      assert {[%{id: 2}], %{has_more?: false}} =
               API.list_payments(
                 %{conn | session_token: "a session token", company_id: 12},
                 cursor
               )
    end
  end

  describe "submit_payment/1" do
    test "creates a payment", %{conn: conn} do
      expect_signed_request(conn, :post, "/user/543/monetary-account/234/payment", [
        %{
          "Id" => %{
            "id" => 9876
          }
        }
      ])

      assert :ok =
               API.submit_payment(
                 %{conn | company_id: 543, account_id: 234},
                 %{
                   amount_in_cents: 1234,
                   to_iban: "GB33BUKB20201555555555",
                   to_name: "Pietje",
                   description: "Bla"
                 }
               )
    end
  end

  def expect_request(%Conn{endpoint: endpoint}, method, path, response)
      when is_function(response) do
    url = endpoint <> path

    Bunq.MockHTTP
    |> expect(:request!, fn ^method, ^url, request_body, headers, _options ->
      %{body: Jason.encode!(response.(headers, request_body))}
    end)
  end

  def expect_request(%Conn{} = conn, method, path, response) do
    expect_request(conn, method, path, fn _headers, _body -> response end)
  end

  def expect_signed_request(%Conn{private_key: private_key} = conn, method, path, response) do
    expect_request(conn, method, path, fn headers, request_body ->
      public_key = {:RSAPublicKey, elem(private_key, 2), elem(private_key, 3)}
      assert :lists.keymember("X-Bunq-Client-Authentication", 1, headers)
      {_, signature} = :lists.keyfind("X-Bunq-Client-Signature", 1, headers)
      assert :public_key.verify(request_body, :sha256, Base.decode64!(signature), public_key)
      response
    end)
  end
end
