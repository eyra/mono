defmodule Systems.Notify.System do
  use Mica.System

  def notify_channels, do: %{email: Systems.Notify.Channel.Email, na: Systems.Notify.Channel.NA}
end
