defmodule Systems.Feldspar.Private do
  @moduledoc false
  def get_backend do
    :core
    |> Application.fetch_env!(:feldspar)
    |> Access.fetch!(:backend)
  end
end
