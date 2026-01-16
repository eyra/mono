defmodule Systems.Org.UserView do
  @moduledoc """
  Embedded LiveView for managing organisation members.

  Uses PeopleEditorView for the add/remove functionality.
  """
  use CoreWeb, :embedded_live_view

  alias Frameworks.Pixel.AlertBanner
  alias Systems.Account
  alias Systems.Org

  def dependencies(), do: [:node_id, :current_user, :locale]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{node_id: node_id}}) do
    Org.Public.get_node!(node_id, Org.NodeModel.preload_graph(:full))
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("add_all_domain_matched", _, %{assigns: %{model: org}} = socket) do
    members = Org.Public.list_members(org)
    owners = Org.Public.list_owners(org)
    domain_matched = Org.Public.find_domain_matched_users(org.domains, members ++ owners)

    Enum.each(domain_matched, fn user ->
      Org.Public.add_member(org, user)
    end)

    {:noreply, update_view_model(socket)}
  end

  @impl true
  def handle_info({:add_user, %{user: user}}, %{assigns: %{model: org}} = socket) do
    Org.Public.add_member(org, user)
    {:noreply, update_view_model(socket)}
  end

  @impl true
  def handle_info({:remove_user, %{user: user}}, %{assigns: %{model: org}} = socket) do
    Org.Public.remove_member(org, user)
    {:noreply, update_view_model(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />

        <%= if @vm.domain_banner do %>
          <AlertBanner.action {@vm.domain_banner} />
          <.spacing value="M" />
        <% end %>

        <.live_component
          module={Account.PeopleEditorComponent}
          id="members_editor"
          title={@vm.title}
          people={@vm.people}
          users={@vm.users}
          current_user={@current_user}
        />
      </Area.content>
    </div>
    """
  end
end
