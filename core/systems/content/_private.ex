defmodule Systems.Content.Private do
  def get_backend do
    :core
    |> Application.fetch_env!(:content)
    |> Access.fetch!(:backend)
  end
end
