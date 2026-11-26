defmodule Systems.License.Notify do
  @moduledoc """
  The notifications about a user's license (`License.Public.tell/4`), each
  shown as a next action on the Actions channel (`:na`).
  """
  use Systems.Notify.EventDeclaration

  event(:license_given, channels: [:na], next_action: Systems.License.NextActions.Given)

  event(:license_switched_off,
    channels: [:na],
    next_action: Systems.License.NextActions.SwitchedOff
  )

  event(:license_reminder,
    channels: [:na],
    next_action: Systems.License.NextActions.Reminder,
    priority: :high
  )

  event(:license_ended, channels: [:na], next_action: Systems.License.NextActions.Ended)
end
