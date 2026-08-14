defmodule Systems.Notify.EventAttrs do
  @moduledoc """
  Input struct for `Systems.Notify.Public.record_event/1`. Keeps the
  contract explicit so callers get a `FunctionClauseError` on the wrong
  shape instead of a silent `nil` deep in normalize.
  """

  @enforce_keys [:type, :subject_user]
  defstruct [
    :type,
    :subject_user,
    :actor_user,
    :correlation_id,
    :source,
    metadata: %{}
  ]
end
