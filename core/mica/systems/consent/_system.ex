defmodule Systems.Consent.System do
  use Core.System

  def signal_handlers, do: [Systems.Consent.Switch]
end
