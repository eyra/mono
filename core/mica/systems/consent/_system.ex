defmodule Systems.Consent.System do
  use Mica.System

  def signal_handlers, do: [Systems.Consent.Switch]
end
