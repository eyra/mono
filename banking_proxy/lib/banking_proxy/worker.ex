defmodule BankingProxy.Worker do
  def start_link do
    :ranch.start_listener(
      :api,
      :ranch_ssl,
      %{
        socket_opts: [
          port: 5555,
          certfile: cert(:certfile),
          cacertfile: cert(:cacertfile),
          keyfile: cert(:keyfile)
          # fail_if_no_peer_cert: true
          # verify: :verify_peer
        ]
      },
      BankingProxy.Protocol,
      banking_backend: banking_backend()
    )
  end

  def cert(config_key) do
    Application.get_env(:banking_proxy, config_key)
  end

  defp banking_backend do
    Application.get_env(:banking_proxy, :banking_backend)
  end
end
