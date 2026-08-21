defmodule Systems.Assignment.Notify do
  @moduledoc """
  Notification events published by the Assignment system.

  Add new events here as they're introduced elsewhere in the codebase; the
  channel list drives which delivery adapters `Systems.Notify.Dispatcher`
  fans out to.
  """
  use Systems.Notify.EventDeclaration

  event(:contribution_accepted, channels: [:email, :na])
  event(:contribution_declined, channels: [:email, :na])
end
