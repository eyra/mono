defmodule Port.Console.Page do
  @moduledoc """
  The console screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :console
  import CoreWeb.Layouts.Workspace.Component

  import CoreWeb.UI.Content

  alias Frameworks.Pixel.Text

  alias Systems.{
    Project,
    NextAction
  }

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    preload = Project.Model.preload_graph(:down)

    content_items =
      user
      |> Project.Public.list_owned_projects(preload: preload)
      |> Enum.map(&convert_to_vm(socket, &1))

    socket =
      socket
      |> update_menus()
      |> assign(content_items: content_items)
      |> assign(next_best_action: NextAction.Public.next_best_action(user))

    {:ok, socket}
  end

  def handle_info({:handle_auto_save_done, _}, socket) do
    socket |> update_menus()
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.workspace title={dgettext("eyra-ui", "dashboard.title")} menus={@menus}>
      <Area.content>
        <Margin.y id={:page_top} />
        <%= if @next_best_action do %>
          <div>
            <NextAction.View.highlight {@next_best_action} />
            <.spacing value="XL" />
          </div>
        <% end %>
        <Text.title2>
          <%= dgettext("eyra-dashboard", "recent-items.title") %>
        </Text.title2>
        <.list items={@content_items} />
      </Area.content>
    </.workspace>
    """
  end

  def convert_to_vm(
        _socket,
        %{
          name: name,
          root: %{
            items: [item]
          }
        }
      ) do
    %{
      path: ~p"/project/item/#{item.id}/content",
      title: name,
      subtitle: "<subtitle>",
      tag: %{text: "Concept", type: :success},
      level: :critical,
      image: nil,
      quick_summary: ""
    }
  end

  def convert_to_vm(
        _socket,
        %{
          name: name,
          root: %{
            id: root_node_id
          }
        }
      ) do
    %{
      path: ~p"/project/node/#{root_node_id}",
      title: name,
      subtitle: "<subtitle>",
      tag: nil,
      level: :critical,
      image: nil,
      quick_summary: ""
    }
  end
end
