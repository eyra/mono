defmodule Next.Systems.Citizen.System do
  use Mica.System

  def directors, do: %{citizen: Next.Systems.Citizen.Director}
end
