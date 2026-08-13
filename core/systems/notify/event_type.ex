defmodule Systems.Notify.EventType do
  @moduledoc """
  Global registry of notification event types → channel routing.

  Built at first-use from all modules listed in
  `config :core, Systems.Notify, notifiers: [...]`; each notifier declares
  its events via `use Systems.Notify.EventDeclaration`.

  Cached in `:persistent_term` — one lookup at first call, direct-map after.
  """

  @cache_key {__MODULE__, :registry}

  def known?(type) when is_binary(type), do: Map.has_key?(registry(), type)
  def known?(type) when is_atom(type), do: known?(Atom.to_string(type))

  def channels_for(type) when is_binary(type), do: Map.get(registry(), type, [])
  def channels_for(type) when is_atom(type), do: channels_for(Atom.to_string(type))

  def all, do: Map.keys(registry())

  @doc """
  Force a rebuild — useful in tests that swap notifier config on the fly.
  """
  def reset do
    :persistent_term.erase(@cache_key)
    :ok
  end

  defp registry do
    case :persistent_term.get(@cache_key, nil) do
      nil -> build()
      map -> map
    end
  end

  defp build do
    notifiers =
      Application.get_env(:core, Systems.Notify, [])
      |> Keyword.get(:notifiers, [])

    registry =
      notifiers
      |> Enum.flat_map(& &1.notify_events())
      |> Map.new(fn {type, opts} ->
        {to_string(type), Keyword.get(opts, :channels, [])}
      end)

    :persistent_term.put(@cache_key, registry)
    registry
  end
end
