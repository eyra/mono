defmodule Systems.Feldspar.Private do
  def get_backend do
    Mica.Env.fetch!(:feldspar)
    |> Access.fetch!(:backend)
  end
end
