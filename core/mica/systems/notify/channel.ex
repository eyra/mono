defmodule Systems.Notify.Channel do
  @moduledoc """
  Channel-adapter behaviour. A channel takes a persisted `MessageModel` (with
  its event context) and ships it. The dispatcher handles status transitions
  based on the return value — adapters just focus on delivery.

  A channel MUST also expose `build_payload/1` — turning an event into the
  channel-specific payload the dispatcher persists on the message. This
  keeps rendering (subject/body/action-params) next to delivery.
  """

  alias Systems.Notify.EventModel
  alias Systems.Notify.MessageModel

  @callback build_payload(%EventModel{}) :: {:ok, map()} | {:error, term()} | :skip
  @callback deliver(%MessageModel{}) :: :ok | {:error, term()}

  @doc """
  Called when `Systems.Notify.Public.mark_seen/2` matches this message.
  Adapters translate "user has seen the outcome" into channel-specific side
  effects (NA clears the NBA, future InApp marks the inbox record as read,
  Email is a no-op). Optional — dispatch handles absence as a no-op.
  """
  @callback mark_seen(%MessageModel{}) :: :ok | {:error, term()}
  @optional_callbacks [mark_seen: 1]
end
