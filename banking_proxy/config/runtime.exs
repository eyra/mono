import Config

if config_env() == :prod do
  config :banking_proxy,
    backend_params: [
      endpoint: System.fetch_env!("BUNQ_ENDPOINT"),
      keyfile: System.fetch_env!("BUNQ_KEYFILE"),
      iban: System.fetch_env!("BUNQ_IBAN"),
      api_key: System.fetch_env!("BUNQ_API_KEY"),
      installation_token: System.fetch_env!("BUNQ_INSTALLATION_TOKEN"),
      device_id: System.fetch_env!("BUNQ_DEVICE_ID")
    ],
    certfile: System.fetch_env!("BANKING_CERTFILE"),
    cacertfile: System.fetch_env!("BANKING_CACERTFILE"),
    keyfile: System.fetch_env!("BANKING_KEYFILE")
end
