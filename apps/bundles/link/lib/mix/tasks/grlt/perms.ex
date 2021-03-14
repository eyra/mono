defmodule Mix.Tasks.Grlt.Perms do
  @moduledoc """
  A Mix task to list all the permission with their role assignments.
  """
  use Mix.Task
  alias Core.Authorization

  def run(_) do
    Authorization.permission_map()
    |> Enum.map(fn {permission, roles} -> [permission, Enum.join(roles, ", ")] end)
    |> TableRex.quick_render!(["Permission", "Roles"])
    |> IO.puts()
  end
end
