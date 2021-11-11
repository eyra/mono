defmodule BankingProxy.Server do
  @behaviour :ranch_protocol

  def start_link(ref, transport, opts) do
    pid = :erlang.spawn_link(__MODULE__, :init, [ref, transport, opts])
    {:ok, pid}
  end

  def init(ref, transport, _opts = []) do
    {:ok, socket} = :ranch.handshake(ref)
    loop(socket, transport)
  end

  def loop(socket, transport) do
    case transport.recv(socket, 0, 60000) do
      {:ok, data} when data != <<4>> ->
        transport.send(socket, data)
        loop(socket, transport)

      _ ->
        :ok = transport.close(socket)
    end
  end
end
