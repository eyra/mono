defmodule Next.Systems.Student.System do
  use Mica.System

  def directors, do: %{student: Next.Systems.Student.Director}

  def signal_handlers, do: [Next.Systems.Student.Switch]
end
