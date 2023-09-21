defmodule Systems.Feldspar.Internal do
  def get_backend do
    :core
    |> Application.fetch_env!(:feldspar)
    |> Access.fetch!(:backend)
  end
end
