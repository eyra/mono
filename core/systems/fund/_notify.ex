defmodule Systems.Fund.Notify do
  @moduledoc """
  Notification events published by the Fund system.

  Both events are email-only: they are about money the participant has to act
  on (or already lost the chance to act on), which belongs in their inbox
  rather than only behind a login they are — by definition — not visiting.
  """
  use Systems.Notify.EventDeclaration

  event(:reward_dormancy_warning, channels: [:email])
  event(:reward_auto_donated, channels: [:email])
end
