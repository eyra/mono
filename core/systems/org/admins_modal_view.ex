defmodule Systems.Org.AdminsModalView do
  @moduledoc """
  Modal view for managing organisation admins.

  Uses the reusable PeopleEditorComponent.
  """
  use CoreWeb, :modal_live_view
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Account
  alias Systems.Org

  def get_model(:not_mounted_at_router, %{"org_id" => org_id}, _assigns) do
    Org.Public.get_node!(org_id, Org.NodeModel.preload_graph(:full))
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_info({:add_user, %{user: user}}, %{assigns: %{model: org}} = socket) do
    :ok = Org.Public.assign_owner(org, user)
    {:noreply, update_view_model(socket)}
  end

  @impl true
  def handle_info({:remove_user, %{user: user}}, %{assigns: %{model: org}} = socket) do
    Org.Public.revoke_owner(org, user)
    {:noreply, update_view_model(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="org-admins-modal" data-testid="org-admins-modal">
      <.live_component
        module={Account.PeopleEditorComponent}
        id="org_admins_editor"
        title={@vm.title}
        people={@vm.people}
        users={@vm.users}
        current_user={@current_user}
      />
    </div>
    """
  end
end
