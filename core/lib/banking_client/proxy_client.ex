defmodule BankingClient.ProxyClient do
  alias BankingClient.API
  @behaviour API
  @timeout :infinity

  @impl API
  def send_message(message) do
    conf = Application.fetch_env!(:core, BankingClient)
    host = Keyword.fetch!(conf, :host)
    port = Keyword.fetch!(conf, :port)
    cacertfile = Keyword.fetch!(conf, :cacertfile)
    certfile = Keyword.fetch!(conf, :certfile)
    keyfile = Keyword.fetch!(conf, :keyfile)

    {:ok, socket} =
      :ssl.connect(
        host,
        port,
        [
          active: false,
          cacertfile: cacertfile,
          certfile: certfile,
          keyfile: keyfile,
          packet: :line,
          verify: :verify_peer
        ],
        @timeout
      )

    :ok = :ssl.send(socket, Jason.encode!(message) <> "\n")
    {:ok, data} = :ssl.recv(socket, 0, @timeout)
    :ssl.close(socket)

    Jason.decode!(data)
  end
end
