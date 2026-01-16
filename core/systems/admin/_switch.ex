defmodule Systems.Admin.Switch do
  use Frameworks.Concept.Switch

  alias Systems.Admin
  alias Systems.Observatory
  alias Systems.Org

  @impl true
  def intercept({:bank_account, _}, %{from_pid: from_pid}) do
    update_routed(Admin.ConfigPage, %{id: :singleton}, from_pid)
    :ok
  end

  @impl true
  def intercept({:pool, _}, %{pool: %{director: :citizen}, from_pid: from_pid}) do
    update_routed(Admin.ConfigPage, %{id: :singleton}, from_pid)
    :ok
  end

  @impl true
  def intercept({:org_node, _action}, %{org_node: _org_node, from_pid: from_pid}) do
    update_embedded(Admin.OrgView, Observatory.SingletonModel.instance(), from_pid)
    update_embedded(Org.ArchiveModalView, Observatory.SingletonModel.instance(), from_pid)
    :ok
  end
end
