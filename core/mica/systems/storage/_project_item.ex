defmodule Systems.Storage.ProjectItem do
  @moduledoc "The `storage_endpoint` project item type (`Mica.ProjectItem`)."
  use Mica.ProjectItem

  @impl true
  def type, do: "storage_endpoint"

  @impl true
  def schema, do: Systems.Storage.EndpointModel
end
