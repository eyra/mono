defmodule Systems.Rate.Server do
  use GenServer
  require Logger

  alias Systems.Rate.Quota, as: Quota
  alias Systems.Rate.LeakyBucketState, as: State
  alias Systems.Rate.LeakyBucketAlgorithm, as: Algorithm

  # PUBLIC API

  def request_permission(service, client_id, byte_count)
      when is_binary(service) and is_binary(client_id) and is_number(byte_count) do
    GenServer.call(__MODULE__, {:request_permission, {service, client_id, byte_count}})
  end

  # SERVER

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @impl true
  def init(args) do
    prune_interval = Keyword.get(args, :prune_interval, 60 * 60 * 1000)

    quotas =
      Keyword.get(args, :quotas, [])
      |> Enum.map(&Quota.init(&1))

    Logger.notice("[Rate] quotas: #{inspect(quotas)}")

    {:ok, State.init(prune_interval, quotas) |> schedule_prune()}
  end

  @impl true
  def handle_info(:prune, state) do
    {
      :noreply,
      state
      |> State.prune()
      |> schedule_prune()
    }
  end

  @impl true
  def handle_call({:request_permission, {service, client_id, packet_size}}, _from, state) do
    {result, state} = Algorithm.request_permission(state, service, client_id, packet_size)
    {:reply, result, state}
  end

  defp schedule_prune(%State{prune_interval: prune_interval, quotas: quotas} = state) do
    if Enum.count(quotas) > 0 do
      Process.send_after(self(), :prune, prune_interval)
    end

    state
  end
end
