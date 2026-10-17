defmodule Systems.Feldspar.Private do
  def get_backend do
    Core.Env.fetch!(:feldspar)
    |> Access.fetch!(:backend)
  end
end
