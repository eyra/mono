defmodule Mix.Tasks.Unsplash.RandomImages do
  @moduledoc false

  use Mix.Task

  def run(_) do
    :application.ensure_all_started(:hackney)

    30
    |> Core.ImageCatalog.Unsplash.random()
    |> Enum.map(&IO.puts/1)
  end
end
