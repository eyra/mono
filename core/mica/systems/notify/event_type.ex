defmodule Systems.Notify.EventType do
  @moduledoc """
  Notification event types and the channels each is routed to, from the
  notifiers of the SaaS's systems (`Mica.SaaS.notify_events/0`). Each notifier
  declares its events via `use Systems.Notify.EventDeclaration`.
  """

  def known?(type) when is_binary(type), do: Map.has_key?(Mica.SaaS.notify_events(), type)
  def known?(type) when is_atom(type), do: known?(Atom.to_string(type))

  def channels_for(type) when is_binary(type), do: Map.get(Mica.SaaS.notify_events(), type, [])
  def channels_for(type) when is_atom(type), do: channels_for(Atom.to_string(type))

  def all, do: Map.keys(Mica.SaaS.notify_events())
end
