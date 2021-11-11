defmodule BankingProxy.Protocol do
  @behaviour :ranch_protocol

  @read_timeout 9999

  def start_link(ref, transport, opts) do
    pid = :erlang.spawn_link(__MODULE__, :init, [ref, transport, opts])
    {:ok, pid}
  end

  def init(ref, transport, opts) do
    banking_backend = Keyword.fetch!(opts, :banking_backend)
    {:ok, socket} = :ranch.handshake(ref)
    loop(banking_backend, "", socket, transport)
  end

  def loop(banking_backend, buffer, socket, transport) do
    case transport.recv(socket, 0, @read_timeout) do
      {:ok, data} ->
        {buffer, messages} = parse(buffer, data)

        messages
        |> Enum.map(&dispatch_message(banking_backend, &1))
        |> Enum.each(&send_response(transport, socket, &1))

        loop(banking_backend, buffer, socket, transport)

      _ ->
        :ok = transport.close(socket)
    end
  end

  def parse(buffer, data) do
    {encoded_messages, [buffer]} =
      (buffer <> data)
      |> :binary.split(<<31>>, [:global])
      |> Enum.split(-1)

    messages = Enum.map(encoded_messages, &Jason.decode!/1)
    {buffer, messages}
  end

  def dispatch_message(banking_backend, %{"call" => "list_payments"}) do
    {payments, cursor} = banking_backend.list_payments()
    %{payments: payments, cursor: cursor}
  end

  def dispatch_message(_banking_backend, %{"call" => undefined_call}) do
    %{
      "error" => %{
        "type" => "undefined",
        "message" => "Call `#{undefined_call}` is not supported"
      }
    }
  end

  def dispatch_message(_banking_backend, _) do
    %{
      "error" => %{
        "type" => "malformed",
        "message" => "Message requires `call` key"
      }
    }
  end

  def send_response(transport, socket, response) do
    transport.send(socket, Jason.encode!(response) <> <<31>>)
  end
end
