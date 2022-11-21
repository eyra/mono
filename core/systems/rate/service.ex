defmodule Systems.Rate.Service do
  use GenServer

  # PUBLIC API

  def request(service, client_id, byte_count) when is_atom(service) and is_binary(client_id) and is_number(byte_count) do
    GenServer.call(__MODULE__, {:request, {service, client_id, byte_count}})
  end

  # SERVER


  def start_link([]) do
    init_args = [azure_blob: [
      [
        scope: :local,
        window: :minute,
        limit: 1000000
      ],
      [
        scope: :global,
        window: :minute,
        limit: 1000000
      ]
    ]]

    GenServer.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    state = []
    {:ok, state}
  end

  @impl true
  def handle_call({:request, _args}, _from, state) do
    {:ok, true, state }
  end

end
