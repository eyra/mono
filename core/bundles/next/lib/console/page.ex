defmodule Next.Console.Page do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :console
  import CoreWeb.Layouts.Workspace.Component

  import CoreWeb.UI.Content

  alias Frameworks.Pixel.Text

  alias Systems.{
    Project,
    NextAction,
    Benchmark
  }

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    spot_items =
      user
      |> Benchmark.Public.list_spots(Benchmark.SpotModel.preload_graph([:tool]))
      |> Enum.map(&convert_to_vm(socket, &1))

    project_items =
      user
      |> Project.Public.list_owned_projects(preload: Project.Model.preload_graph(:down))
      |> Enum.map(&convert_to_vm(socket, &1))

    content_items = spot_items ++ project_items

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
          <span class="text-primary"> <%= Enum.count(@content_items) %></span>
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
            id: root_node_id
          }
        }
      ) do
    %{
      path: ~p"/project/node/#{root_node_id}",
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
          id: spot_id,
          name: name,
          updated_at: updated_at,
          tool: %{
            id: tool_id,
            title: title,
            status: status
          }
        }
      ) do
    tag = get_tag(status)

    quick_summary =
      updated_at
      |> CoreWeb.UI.Timestamp.apply_timezone()
      |> CoreWeb.UI.Timestamp.humanize()
      |> Macro.camelize()

    %{
      path: ~p"/benchmark/#{tool_id}/#{spot_id}",
      title: title,
      subtitle: "#{name}",
      tag: tag,
      level: :critical,
      image: nil,
      quick_summary: quick_summary
    }
  end

  defp get_tag(:concept), do: %{type: :warning, text: dgettext("eyra-project", "label.concept")}
  defp get_tag(:online), do: %{type: :success, text: dgettext("eyra-project", "label.online")}
  defp get_tag(:offline), do: %{type: :delete, text: dgettext("eyra-project", "label.offline")}
  defp get_tag(:idle), do: %{type: :idle, text: dgettext("eyra-project", "label.idle")}
end
