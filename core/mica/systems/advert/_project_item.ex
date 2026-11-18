defmodule Systems.Advert.ProjectItem do
  @moduledoc "The `advert` project item type (`Mica.ProjectItem`)."
  use Mica.ProjectItem

  @impl true
  def type, do: "advert"

  @impl true
  def schema, do: Systems.Advert.Model
end
