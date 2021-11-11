defmodule BankingProxy.App do
  use Application

  def start(_type, _args) do
    {:ok, _} =
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
      |> IO.inspect()

    BankingProxy.Supervisor.start_link()
  end

  defp banking_backend do
    Application.get_env(:banking_proxy, :banking_backend)
  end

  def cert(config_key) do
    Application.get_env(:banking_proxy, config_key)
  end
end
