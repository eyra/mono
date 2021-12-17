defmodule BankingProxy.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, [])
  end

  @impl true
  def init(:ok) do
    children = [
      {Bunq, Application.fetch_env!(:banking_proxy, :backend_params)},
      %{
        id: :ssl_listener,
        start:
          {:ranch, :start_listener,
           [
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
             banking_backend()
           ]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def cert(config_key) do
    Application.get_env(:banking_proxy, config_key)
  end

  defp banking_backend do
    Application.get_env(:banking_proxy, :banking_backend)
  end
end
