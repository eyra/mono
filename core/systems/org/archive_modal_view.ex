defmodule Systems.Org.ArchiveModalView do
  @moduledoc """
  Modal view for displaying and restoring archived organisations.

  Provides:
  - List of archived organisations
  - Search functionality
  - Filter by hierarchy (root/nested)
  - Restore button per organisation
  """
  use CoreWeb, :modal_live_view
  use Frameworks.Pixel

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.SearchBar
  alias Frameworks.Pixel.Text

  alias Systems.Observatory
  alias Systems.Org

  def get_model(:not_mounted_at_router, _session, _assigns) do
    Observatory.SingletonModel.instance()
  end

  @impl true
  def mount(:not_mounted_at_router, %{"locale" => locale}, socket) do
    {
      :ok,
      socket
      |> assign(
        locale: locale,
        query: nil,
        query_string: "",
        active_filters: []
      )
    }
  end

  @impl true
  def handle_event("restore_org", %{"item" => org_id_string}, socket) do
    org_id = String.to_integer(org_id_string)
    org = Org.Public.get_node!(org_id)
    {:ok, _} = Org.Public.restore(org)

    {:noreply, update_view_model(socket)}
  end

  @impl true
  def consume_event(
        %{name: :search_query, payload: %{query: query, query_string: query_string}},
        socket
      ) do
    {
      :stop,
      socket
      |> assign(query: query, query_string: query_string)
      |> update_view_model()
    }
  end

  @impl true
  def consume_event(
        %{name: :active_item_ids, payload: %{active_item_ids: active_filters}},
        socket
      ) do
    {
      :stop,
      socket
      |> assign(active_filters: active_filters)
      |> update_view_model()
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="archived-orgs-modal">
      <div class="flex flex-row items-center justify-center">
        <div class="h-full">
          <Text.title2 margin="" data-testid="archived-org-title"><%= @vm.title %> <span class="text-primary"><%= @vm.org_count %></span></Text.title2>
        </div>
        <div class="flex-grow">
        </div>
      </div>

      <.spacing value="M" />

      <.live_component
        module={SearchBar}
        id={:archived_org_search_bar}
        query_string={@query_string}
        placeholder={@vm.search_placeholder}
        debounce="200"
      />
      <.spacing value="M" />

      <table class="w-full" data-testid="archived-org-list">
        <%= for org <- @vm.organisations do %>
          <tr class="h-14 border-b border-grey5" data-testid="archived-org-item">
            <td class="pr-4">
              <Text.label><%= org.title %></Text.label>
            </td>
            <td>
              <div class="flex flex-row justify-end">
                <Button.dynamic_bar buttons={org.action_buttons} />
              </div>
            </td>
          </tr>
        <% end %>
      </table>
    </div>
    """
  end
end
