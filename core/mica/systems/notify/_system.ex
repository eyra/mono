defmodule Systems.Notify.System do
  use Core.System

  def notify_channels, do: %{email: Systems.Notify.Channel.Email, na: Systems.Notify.Channel.NA}
end
