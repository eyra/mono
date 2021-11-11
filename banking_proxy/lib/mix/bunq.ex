defmodule Mix.Tasks.Bunq do
  @moduledoc "Run Bunq"
  @shortdoc "Call Bunq"

  use Mix.Task

  @key_file "private_key.pem"
  @settings_file "bunq.json"

  @impl Mix.Task
  def run(_) do
    :application.ensure_all_started(:hackney)

    private_key =
      if File.exists?(@key_file) do
        key_pem = File.read!(@key_file)

        :public_key.pem_decode(key_pem)
        |> Enum.map(&:public_key.pem_entry_decode/1)
        |> List.first()
      else
        private_key = Bunq.API.generate_key()
        private_pem = :public_key.pem_entry_encode(:RSAPrivateKey, private_key)

        key_pem = :public_key.pem_encode([private_pem])
        File.write!(@key_file, key_pem)
        private_key
      end

    settings =
      if File.exists?(@settings_file) do
        File.read!(@settings_file)
        |> Jason.decode!(keys: :atoms!)
      else
        %{}
      end
      |> IO.inspect()

    conn = Bunq.API.create_conn(Bunq.API.production_endpoint(), private_key)

    conn = Map.merge(conn, settings)

    conn =
      %{conn | api_key: System.fetch_env!("BUNQ_API_KEY")}
      |> Map.merge(settings)

    conn =
      if is_nil(conn.installation_token) do
        Bunq.API.create_installation(conn)
      else
        conn
      end

    store_settings(conn)

    conn =
      if is_nil(conn.device_id) do
        Bunq.API.register_device(conn)
      else
        conn
      end

    store_settings(conn)

    conn =
      Bunq.API.start_session(conn)
      |> IO.inspect()

    accounts =
      Bunq.API.list_accounts(conn)
      |> IO.inspect()

    account_id = accounts |> List.first() |> Map.get(:id)

    Bunq.API.list_payments(conn, account_id)
    |> IO.inspect()

    [
      %{
        "Payment" => %{
          "address_billing" => nil,
          "address_shipping" => nil,
          "alias" => %{
            "avatar" => %{
              "anchor_uuid" => nil,
              "image" => [
                %{
                  "attachment_public_uuid" => "479dc46b-550d-46fa-8451-21228d09c6c1",
                  "content_type" => "image/png",
                  "height" => 1023,
                  "width" => 1024
                }
              ],
              "style" => "NONE",
              "uuid" => "bcfbc254-a642-4390-8c29-397b362b7d53"
            },
            "country" => "NL",
            "display_name" => "9 BitCat",
            "iban" => "NL10BUNQ2066367605",
            "is_light" => false,
            "label_user" => %{
              "avatar" => %{
                "anchor_uuid" => "e1b26762-3f58-4b37-b442-847fe91eaad7",
                "image" => [
                  %{
                    "attachment_public_uuid" => "fb14adeb-2ea5-40ea-9d51-b76b03358b24",
                    "content_type" => "image/png",
                    "height" => 640,
                    "width" => 640
                  }
                ],
                "style" => "NONE",
                "uuid" => "65e95be1-230e-4542-9e7a-e8f7b2a59d7f"
              },
              "country" => "NL",
              "display_name" => "9 BitCat",
              "public_nick_name" => "9 BitCat",
              "type" => "COMPANY",
              "uuid" => "e1b26762-3f58-4b37-b442-847fe91eaad7"
            }
          },
          "amount" => %{"currency" => "EUR", "value" => "-0.21"},
          "attachment" => [],
          "balance_after_mutation" => %{"currency" => "EUR", "value" => "24.79"},
          "batch_id" => nil,
          "counterparty_alias" => %{
            "avatar" => %{
              "anchor_uuid" => nil,
              "image" => [
                %{
                  "attachment_public_uuid" => "32a648e6-53e8-4e7b-a27d-0673595284a6",
                  "content_type" => "image/jpeg",
                  "height" => 1024,
                  "width" => 1024
                }
              ],
              "style" => "NONE",
              "uuid" => "50ac593a-65fc-4152-aa06-8b0a9dd57797"
            },
            "country" => "NL",
            "display_name" => "Jeroen",
            "iban" => "NL30BUNQ2066411671",
            "is_light" => false,
            "label_user" => %{
              "avatar" => %{
                "anchor_uuid" => "fc3b4088-5bb5-4fc7-8a72-6044bbcb74bb",
                "image" => [
                  %{
                    "attachment_public_uuid" => "2a79c91c-3f00-4ead-99f3-854453bf8706",
                    "content_type" => "image/png",
                    "height" => 640,
                    "width" => 640
                  }
                ],
                "style" => "NONE",
                "uuid" => "6c533558-ec03-4a5a-b522-809e98899da5"
              },
              "country" => "NL",
              "display_name" => "Jeroen",
              "public_nick_name" => "Jeroen",
              "type" => "PERSON",
              "uuid" => "fc3b4088-5bb5-4fc7-8a72-6044bbcb74bb"
            }
          },
          "created" => "2021-11-20 16:23:10.703069",
          "description" => "Testing",
          "geolocation" => nil,
          "id" => 624_878_455,
          "merchant_reference" => nil,
          "monetary_account_id" => 3_962_720,
          "payment_auto_allocate_instance" => nil,
          "request_reference_split_the_bill" => [],
          "scheduled_id" => nil,
          "sub_type" => "PAYMENT",
          "type" => "BUNQ",
          "updated" => "2021-11-20 16:23:10.703069"
        }
      },
      %{
        "Payment" => %{
          "address_billing" => nil,
          "address_shipping" => nil,
          "alias" => %{
            "avatar" => %{
              "anchor_uuid" => nil,
              "image" => [
                %{
                  "attachment_public_uuid" => "479dc46b-550d-46fa-8451-21228d09c6c1",
                  "content_type" => "image/png",
                  "height" => 1023,
                  "width" => 1024
                }
              ],
              "style" => "NONE",
              "uuid" => "bcfbc254-a642-4390-8c29-397b362b7d53"
            },
            "country" => "NL",
            "display_name" => "9 BitCat",
            "iban" => "NL10BUNQ2066367605",
            "is_light" => false,
            "label_user" => %{
              "avatar" => %{
                "anchor_uuid" => "fc3b4088-5bb5-4fc7-8a72-6044bbcb74bb",
                "image" => [
                  %{
                    "attachment_public_uuid" => "2a79c91c-3f00-4ead-99f3-854453bf8706",
                    "content_type" => "image/png",
                    "height" => 640,
                    "width" => 640
                  }
                ],
                "style" => "NONE",
                "uuid" => "6c533558-ec03-4a5a-b522-809e98899da5"
              },
              "country" => "NL",
              "display_name" => "J. Vloothuis",
              "public_nick_name" => "Jeroen",
              "type" => "PERSON",
              "uuid" => "fc3b4088-5bb5-4fc7-8a72-6044bbcb74bb"
            }
          },
          "amount" => %{"currency" => "EUR", "value" => "25.00"},
          "attachment" => [],
          "balance_after_mutation" => %{"currency" => "EUR", "value" => "25.00"},
          "batch_id" => nil,
          "counterparty_alias" => %{
            "avatar" => %{
              "anchor_uuid" => nil,
              "image" => [
                %{
                  "attachment_public_uuid" => "9735b3c2-c20f-4413-9349-4e157c9a8a22",
                  "content_type" => "image/jpeg",
                  "height" => 640,
                  "width" => 640
                }
              ],
              "style" => "NONE",
              "uuid" => "ac7e382b-e33b-441f-b773-dfb479b36634"
            },
            "country" => "NL",
            "display_name" => "9 BitCat",
            "iban" => "NL63ASNB0781245885",
            "is_light" => nil,
            "label_user" => %{
              "avatar" => %{
                "anchor_uuid" => "fc3b4088-5bb5-4fc7-8a72-6044bbcb74bb",
                "image" => [
                  %{
                    "attachment_public_uuid" => "2a79c91c-3f00-4ead-99f3-854453bf8706",
                    "content_type" => "image/png",
                    "height" => 640,
                    "width" => 640
                  }
                ],
                "style" => "NONE",
                "uuid" => "6c533558-ec03-4a5a-b522-809e98899da5"
              },
              "country" => "NL",
              "display_name" => "J. Vloothuis",
              "public_nick_name" => "Jeroen",
              "type" => "PERSON",
              "uuid" => "fc3b4088-5bb5-4fc7-8a72-6044bbcb74bb"
            }
          },
          "created" => "2021-11-19 12:07:37.191877",
          "description" => "Topup account NL10BUNQ20663676059BitCat",
          "geolocation" => nil,
          "id" => 624_061_470,
          "merchant_reference" => nil,
          "monetary_account_id" => 3_962_720,
          "payment_auto_allocate_instance" => nil,
          "request_reference_split_the_bill" => [],
          "scheduled_id" => nil,
          "sub_type" => "PAYMENT",
          "type" => "IDEAL",
          "updated" => "2021-11-19 12:07:37.191877"
        }
      }
    ]

    # Bunq.API.submit_payment(conn, %{
    #   account_id: account_id,
    #   amount_in_cents: 21,
    #   to_iban: "NL30BUNQ2066411671",
    #   to_name: "Jeroen Vloothuis",
    #   description: "Testing"
    # })
    # |> IO.inspect()
  end

  defp store_settings(conn) do
    {settings, _} = Map.split(conn, [:installation_token, :device_id])
    File.write!(@settings_file, Jason.encode!(settings))
  end
end
