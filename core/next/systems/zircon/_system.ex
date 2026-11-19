defmodule Next.Systems.Zircon.System do
  use Mica.System

  def tools, do: [Next.Systems.Zircon.Tool]

  def signal_handlers, do: [Next.Systems.Zircon.Switch]
end
