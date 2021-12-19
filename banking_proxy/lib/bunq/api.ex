defmodule Bunq.API do
  @moduledoc """
  API for interacting with the Bunq bank.
  """

  require Logger
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

  def sandbox_endpoint, do: "https://public-api.sandbox.bunq.com"
  def production_endpoint, do: "https://api.bunq.com"

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
      request!(conn, :post, "/v1/sandbox-user-company", "", [], recv_timeout: 99_999)
      |> Map.fetch!("Response")
      |> List.first()
      |> Map.fetch!("ApiKey")
      |> Map.fetch!("api_key")

    %{conn | api_key: api_key}
  end

  def create_installation(%Conn{private_key: private_key} = conn) do
    results =
      request!(conn, :post, "/v1/installation", %{
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
        "/v1/device-server",
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
        "/v1/session-server",
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
      "/v1/user/#{company_id}/monetary-account",
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
      "/v1/user/#{user_id}/monetary-account/#{account_id}/payment?count=200",
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
        "/v1/user/#{company_id}/monetary-account/#{account_id}/payment",
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
      "/v1/user/#{user_id}/monetary-account/#{account_id}/request-inquiry",
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
      date: created,
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
      %{"Error" => [%{"error_description" => error}]} ->
        Logger.error("Bunq error: #{error}")
        {:error, error}

      response ->
        {:ok, response}
    end
  end
end
