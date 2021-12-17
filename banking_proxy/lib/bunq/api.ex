defmodule Bunq.API do
  @moduledoc """
  API for interacting with the Bunq bank.
  """

  alias Bunq.{Conn, Cursor}

  def create_conn(endpoint, private_key) do
    %Conn{endpoint: endpoint, private_key: private_key}
  end

  def create_conn(endpoint, private_key, api_key, installation_token, device_id) do
    %{
      create_conn(endpoint, private_key)
      | api_key: api_key,
        installation_token: installation_token,
        device_id: device_id
    }
  end

  def sandbox_endpoint, do: "https://public-api.sandbox.bunq.com/v1"
  def production_endpoint, do: "https://api.bunq.com/v1"

  def process_request_body(body) when is_binary(body), do: body

  def select_account_with_iban(conn, iban) do
    account_id =
      conn
      |> list_accounts()
      |> Enum.find_value(fn %{id: id, iban: %{account: account_iban}} ->
        iban == account_iban && id
      end)

    %{conn | account_id: account_id}
  end

  def create_sandbox_company(%Conn{} = conn) do
    api_key =
      request!(conn, :post, "/sandbox-user-company", "", [], recv_timeout: 99_999)
      |> Map.fetch!("Response")
      |> List.first()
      |> Map.fetch!("ApiKey")
      |> Map.fetch!("api_key")

    %{conn | api_key: api_key}
  end

  def create_installation(%Conn{private_key: private_key} = conn) do
    results =
      request!(conn, :post, "/installation", %{
        "client_public_key" => public_key_pem(private_key)
      })
      |> Map.fetch!("Response")
      |> Enum.map(fn item ->
        case item do
          %{"Token" => %{"token" => token}} ->
            {:installation_token, token}

          %{"ServerPublicKey" => %{"server_public_key" => server_public_key}} ->
            {:server_public_key, server_public_key}

          _ ->
            {nil, nil}
        end
      end)
      |> Enum.into(%{})
      |> Map.delete(nil)

    Map.merge(conn, results)
  end

  def register_device(%Conn{api_key: api_key, installation_token: installation_token} = conn)
      when is_binary(api_key) and is_binary(installation_token) do
    device_id =
      request!(
        conn,
        :post,
        "/device-server",
        %{
          "description" => "Eyra Bunq",
          "secret" => api_key,
          "permitted_ips" => ["*"]
        },
        [
          {"X-Bunq-Client-Authentication", installation_token}
        ]
      )
      |> Map.fetch!("Response")
      |> List.first()
      |> Map.fetch!("Id")
      |> Map.fetch!("id")

    %{conn | device_id: device_id}
  end

  def start_session(
        %Conn{api_key: api_key, private_key: private_key, installation_token: installation_token} =
          conn
      ) do
    body =
      Jason.encode!(%{
        "secret" => api_key
      })

    signature = :public_key.sign(body, :sha256, private_key) |> Base.encode64()

    results =
      request!(
        conn,
        :post,
        "/session-server",
        body,
        [
          {"X-Bunq-Client-Authentication", installation_token},
          {"X-Bunq-Client-Signature", signature}
        ]
        #
      )
      |> Map.fetch!("Response")
      |> Enum.map(fn item ->
        case item do
          %{"UserCompany" => %{"id" => company_id}} -> {:company_id, company_id}
          %{"Token" => %{"token" => token}} -> {:session_token, token}
          _ -> {nil, nil}
        end
      end)
      |> Enum.into(%{})
      |> Map.delete(nil)

    Map.merge(conn, results)
  end

  def list_accounts(%Conn{company_id: company_id, session_token: session_token} = conn) do
    request!(
      conn,
      :get,
      "/user/#{company_id}/monetary-account",
      "",
      [
        {"X-Bunq-Client-Authentication", session_token}
      ]
      #
    )
    |> Map.fetch!("Response")
    |> Enum.map(fn %{"MonetaryAccountBank" => %{"id" => id, "alias" => aliases}} ->
      %{"name" => iban_name, "value" => iban_account} =
        Enum.find(aliases, &(Map.fetch!(&1, "type") == "IBAN"))

      %{
        id: id,
        iban: %{name: iban_name, account: iban_account}
      }
    end)
  end

  def list_payments(
        %Conn{
          session_token: session_token,
          company_id: user_id,
          account_id: account_id
        } = conn
      ) do
    request!(
      conn,
      :get,
      "/user/#{user_id}/monetary-account/#{account_id}/payment?count=200",
      "",
      [
        {"X-Bunq-Client-Authentication", session_token}
      ]
    )
    |> convert_payments_response()
  end

  def list_payments(
        %Conn{session_token: session_token} = conn,
        %Cursor{future_url: future_url, newer_url: newer_url}
      ) do
    request!(
      conn,
      :get,
      newer_url || future_url,
      "",
      [
        {"X-Bunq-Client-Authentication", session_token}
      ]
    )
    |> convert_payments_response()

    # payments = Enum.map(response, fn %{"Payment"=> %{"counterparty_alias"=>%{
    #   "alias"

    # }}} )

    # %{
    #   cursor: %Cursor{future_url, newer_url, older_url},
    #   payments: payments
    #   has_more?: false

    # }

    # |> Enum.map(fn %{"MonetaryAccountBank" => %{"id" => id, "alias" => aliases}} ->
    #   %{"name" => iban_name, "value" => iban_account} =
    #     Enum.find(aliases, &(Map.fetch!(&1, "type") == "IBAN"))

    #   %{
    #     id: id,
    #     iban: %{name: iban_name, account: iban_account}
    #   }
    # end)

    # [
    #   %{
    #     "Payment" => %{
    #       "address_billing" => nil,
    #       "address_shipping" => nil,
    #       "alias" => %{
    #         "avatar" => %{
    #           "anchor_uuid" => nil,
    #           "image" => [
    #             %{
    #               "attachment_public_uuid" => "479dc46b-550d-46fa-8451-21228d09c6c1",
    #               "content_type" => "image/png",
    #               "height" => 1023,
    #               "width" => 1024
    #             }
    #           ],
    #           "style" => "NONE",
    #           "uuid" => "bcfbc254-a642-4390-8c29-397b362b7d53"
    #         },
    #         "country" => "NL",
    #         "display_name" => "9 BitCat",
    #         "iban" => "NL10BUNQ2066367605",
    #         "is_light" => false,
    #         "label_user" => %{
    #           "avatar" => %{
    #             "anchor_uuid" => "fc3b4088-5bb5-4fc7-8a72-6044bbcb74bb",
    #             "image" => [
    #               %{
    #                 "attachment_public_uuid" => "2a79c91c-3f00-4ead-99f3-854453bf8706",
    #                 "content_type" => "image/png",
    #                 "height" => 640,
    #                 "width" => 640
    #               }
    #             ],
    #             "style" => "NONE",
    #             "uuid" => "6c533558-ec03-4a5a-b522-809e98899da5"
    #           },
    #           "country" => "NL",
    #           "display_name" => "J. Vloothuis",
    #           "public_nick_name" => "Jeroen",
    #           "type" => "PERSON",
    #           "uuid" => "fc3b4088-5bb5-4fc7-8a72-6044bbcb74bb"
    #         }
    #       },
    #       "amount" => %{"currency" => "EUR", "value" => "25.00"},
    #       "attachment" => [],
    #       "balance_after_mutation" => %{"currency" => "EUR", "value" => "25.00"},
    #       "batch_id" => nil,
    #       "counterparty_alias" => %{
    #         "avatar" => %{
    #           "anchor_uuid" => nil,
    #           "image" => [
    #             %{
    #               "attachment_public_uuid" => "9735b3c2-c20f-4413-9349-4e157c9a8a22",
    #               "content_type" => "image/jpeg",
    #               "height" => 640,
    #               "width" => 640
    #             }
    #           ],
    #           "style" => "NONE",
    #           "uuid" => "ac7e382b-e33b-441f-b773-dfb479b36634"
    #         },
    #         "country" => "NL",
    #         "display_name" => "9 BitCat",
    #         "iban" => "NL63ASNB0781245885",
    #         "is_light" => nil,
    #         "label_user" => %{
    #           "avatar" => %{
    #             "anchor_uuid" => "fc3b4088-5bb5-4fc7-8a72-6044bbcb74bb",
    #             "image" => [
    #               %{
    #                 "attachment_public_uuid" => "2a79c91c-3f00-4ead-99f3-854453bf8706",
    #                 "content_type" => "image/png",
    #                 "height" => 640,
    #                 "width" => 640
    #               }
    #             ],
    #             "style" => "NONE",
    #             "uuid" => "6c533558-ec03-4a5a-b522-809e98899da5"
    #           },
    #           "country" => "NL",
    #           "display_name" => "J. Vloothuis",
    #           "public_nick_name" => "Jeroen",
    #           "type" => "PERSON",
    #           "uuid" => "fc3b4088-5bb5-4fc7-8a72-6044bbcb74bb"
    #         }
    #       },
    #       "created" => "2021-11-19 12:07:37.191877",
    #       "description" => "Topup account NL10BUNQ20663676059BitCat",
    #       "geolocation" => nil,
    #       "id" => 624_061_470,
    #       "merchant_reference" => nil,
    #       "monetary_account_id" => 3_962_720,
    #       "payment_auto_allocate_instance" => nil,
    #       "request_reference_split_the_bill" => [],
    #       "scheduled_id" => nil,
    #       "sub_type" => "PAYMENT",
    #       "type" => "IDEAL",
    #       "updated" => "2021-11-19 12:07:37.191877"
    #     }
    #   }
    # ]

    # test: []
  end

  def submit_payment(
        %Conn{
          private_key: private_key,
          session_token: session_token,
          company_id: company_id,
          account_id: account_id
        } = conn,
        %{
          amount_in_cents: amount_in_cents,
          to_iban: to_iban,
          to_name: to_name,
          description: description
        }
      ) do
    body =
      Jason.encode!(%{
        "amount" => %{
          "value" => "#{div(amount_in_cents, 100)}.#{rem(amount_in_cents, 100)}",
          "currency" => "EUR"
        },
        "counterparty_alias" => %{
          "type" => "IBAN",
          "value" => to_iban,
          "name" => to_name
          # "display_name" => to_name,
          # "country" => "NL"
        },
        # "type" => "BUNQ",
        "description" => description
      })

    signature = body |> :public_key.sign(:sha256, private_key) |> Base.encode64()

    response =
      http_request(
        conn,
        :post,
        "/user/#{company_id}/monetary-account/#{account_id}/payment",
        body,
        [
          {"X-Bunq-Client-Authentication", session_token},
          {"X-Bunq-Client-Signature", signature},
          {"X-Bunq-Client-Request-Id", :rand.uniform(9_999_999_999_999_999_999_999)}
        ]
        #
      )
      |> Map.fetch!(:body)
      |> Jason.decode!()

    case response do
      [%{"Id" => %{"id" => _id}}] -> :ok
      %{"Error" => [%{"error_description" => message}]} -> {:error, message}
    end

    # [%{"Id" => %{"id" => 624_878_455}}]

    # %{
    #   "Error" => [
    #     %{
    #       "error_description" => "\"NLAAAA\" is not a valid IBAN.",
    #       "error_description_translated" => "\"NLAAAA\" is not a valid IBAN."
    #     }
    #   ]
    # }
    #
    #
    # %{
    # "Error" => [
    #   %{
    #     "error_additional_parameter" => [
    #       %{
    #         "AdditionalSupportRedirectParameter" => %{
    #           "external_object_id" => 113987,
    #           "external_url" => nil,
    #           "support_redirect" => "BALANCE"
    #         }
    #       }
    #     ],
    #     "error_description" => "Account doesn't have enough money to complete the payment.",
    #     "error_description_translated" => "Account doesn't have enough money to complete the payment."
    #   }
    # ]
    # }
  end

  def request_sandbox_money(%Conn{} = conn, %{
        private_key: private_key,
        session_token: session_token,
        user_id: user_id,
        account_id: account_id
      }) do
    body =
      Jason.encode!(%{
        "amount_inquired" => %{
          "value" => "50",
          "currency" => "EUR"
        },
        "counterparty_alias" => %{
          "type" => "EMAIL",
          "value" => "sugardaddy@bunq.com",
          "name" => "Sugar Daddy"
        },
        "description" => "You're the best!",
        "allow_bunqme" => false
      })

    signature = body |> :public_key.sign(:sha256, private_key) |> Base.encode64()

    request!(
      conn,
      :post,
      "/user/#{user_id}/monetary-account/#{account_id}/request-inquiry",
      body,
      [
        {"X-Bunq-Client-Authentication", session_token},
        {"X-Bunq-Client-Signature", signature},
        {"X-Bunq-Client-Request-Id", :rand.uniform(9_999_999_999_999_999_999_999)}
      ]
      #
    )
    |> Map.fetch!(:body)
    |> Map.fetch!("Response")
  end

  def generate_key do
    :public_key.generate_key({:rsa, 2048, 65_537})
  end

  def public_key_pem(private_key) do
    public_key = {:RSAPublicKey, elem(private_key, 2), elem(private_key, 3)}

    :public_key.pem_encode([:public_key.pem_entry_encode(:SubjectPublicKeyInfo, public_key)])
  end

  def initialize do
    # """
    # Register a device. A device can be a phone (private), computer or a server
    # (public). You can register a new device by using the POST /installation and
    # POST /device-server calls. This will activate your API key. You only need
    # to do this once.
    # """

    # """
    # Open a session. Sessions are temporary and expire after the auto-logout
    # time set for the user account. It can be changed by the account owner in
    # the bunq app.
    # """
  end

  defp convert_payments_response(%{
         "Pagination" => %{
           "future_url" => future_url,
           "newer_url" => newer_url,
           "older_url" => older_url
         },
         "Response" => response
       }) do
    payments = Enum.map(response, &convert_payment/1)

    {
      payments,
      %Cursor{
        future_url: future_url,
        newer_url: newer_url,
        older_url: older_url,
        has_more?: !is_nil(newer_url)
      }
    }
  end

  defp convert_payment(%{
         "Payment" => %{
           "alias" => payment_alias,
           "counterparty_alias" => payment_counterparty_alias,
           "created" => created,
           "description" => description,
           "id" => id,
           "amount" => amount_str
         }
       }) do
    %{
      payment_alias: convert_alias(payment_alias),
      payment_counterparty_alias: convert_alias(payment_counterparty_alias),
      amount_in_cents: convert_amount(amount_str),
      description: description,
      date: convert_date(created),
      id: id
    }
  end

  defp convert_alias(%{"display_name" => name, "iban" => iban}) do
    %{name: name, iban: iban}
  end

  defp convert_amount(%{"currency" => "EUR", "value" => amount_str}) when is_binary(amount_str) do
    [euros, cents] =
      amount_str
      |> String.split(~r"\.")
      |> Enum.map(&String.to_integer/1)

    euros * 100 + cents
  end

  defp convert_date(date_str) do
    NaiveDateTime.from_iso8601(date_str)
  end

  defp http_request(%Conn{endpoint: endpoint}, method, path, body, headers, options \\ []) do
    url = endpoint <> path

    http_client().request!(method, url, body, headers, options)
  end

  defp request(conn, method, path, body, headers, options) do
    conn
    |> http_request(method, path, body, headers, options)
    |> process_response()
  end

  defp request!(conn, method, path, body, headers \\ [], options \\ []) do
    case request(conn, method, path, body, headers, options) do
      {:ok, response} ->
        response

      {:error, _message} ->
        throw(BunqError)
    end
  end

  defp http_client do
    Application.get_env(:bunq, :http_client, Bunq.HTTP)
  end

  defp process_response(response) do
    body =
      response
      |> Map.fetch!(:body)
      |> Jason.decode!()

    case body do
      %{"Error" => [%{"error_description" => error}]} -> {:error, error}
      response -> {:ok, response}
    end
  end
end
