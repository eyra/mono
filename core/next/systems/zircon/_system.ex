defmodule Next.Systems.Zircon.System do
  use Mica.System

  def signal_handlers, do: [Next.Systems.Zircon.Switch]
end
