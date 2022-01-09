import Config

config :banking_proxy,
  banking_backend: Bunq,
  backend_params: [
    endpoint: "https://public-api.sandbox.bunq.com",
    keyfile: "test/bunq.pem",
    iban: "<enter full IBAN here>",
    api_key: "12345",
    installation_token: "1234",
    device_id: "123"
  ],
  certfile: "test/certs/server_certificate.pem",
  cacertfile: "test/certs/ca_certificate.pem",
  keyfile: "test/certs/server_key.pem"
