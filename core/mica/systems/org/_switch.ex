defmodule Systems.Org.Switch do
  use Frameworks.Concept.Switch

  alias Systems.Org

  @impl true
  def intercept({:org_node, _}, %{org_node: org_node, from_pid: from_pid}) do
    org_node = Core.Repo.preload(org_node, Org.NodeModel.preload_graph(:full))
    update_routed(Org.ContentPage, org_node, from_pid)
    :ok
  end
end
