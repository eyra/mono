defmodule Core.ObanConfig do
  @moduledoc """
  Builds the Oban config that `Core.Application` starts, from `config :core, Oban`
  and the queues the systems declare (`c:Core.System.oban_queues/0`).

  Mica adds its own queues: `default` and this node's storage delivery queue.
  The storage delivery queue is named after the node (`storage_delivery_local_core@host`):
  data donation files wait on that node's disk, so only that node may run its jobs.
  """

  alias Systems.Storage

  @doc "Mica's own queues on `node`."
  def queues(node \\ Node.self()) do
    [{Storage.Public.storage_delivery_queue(node), 1}, default: 5]
  end

  @doc """
  `config` with Mica's queues and the `declared` queues. A queue that `config`
  lists keeps the limit set there; `queues: false` (tests) keeps every queue off.
  Raises when a system declares one of Mica's queues.
  """
  def config(config, declared) do
    case Keyword.get(config, :queues, []) do
      false ->
        config

      configured ->
        Keyword.put(config, :queues, Keyword.merge(with_mica_queues(declared), configured))
    end
  end

  defp with_mica_queues(declared) do
    case Enum.filter(Keyword.keys(declared), &Keyword.has_key?(queues(), &1)) do
      [] ->
        queues() ++ declared

      [name | _] ->
        raise ArgumentError, "Oban queue #{inspect(name)} is Mica's; a system can't declare it"
    end
  end
end
