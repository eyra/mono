defmodule Mix.Tasks.Unsplash.RandomImages do
  use Mix.Task

  @moduledoc false

  def run(_) do
    :application.ensure_all_started(:hackney)

    Core.ImageCatalog.Unsplash.random()
    |> Enum.map(&IO.puts/1)
  end
end
