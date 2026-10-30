defmodule Next.Systems.Student.System do
  use Mica.System

  def signal_handlers, do: [Next.Systems.Student.Switch]
end
