defmodule Port.Console.Page do
  @moduledoc """
  The console screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :console

  import CoreWeb.UI.Content

  alias Systems.{
    Campaign,
    NextAction
  }

  alias Frameworks.Pixel.Text
  alias Core.ImageHelpers

  import CoreWeb.Layouts.Workspace.Component

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    preload = Campaign.Model.preload_graph(:full)

    # FIXME: Refactor to use content node
    content_items =
      user
      |> Campaign.Public.list_owned_campaigns(preload: preload)
      |> Enum.map(&Campaign.Model.flatten(&1))
      |> Enum.map(&convert_to_vm(socket, &1))

    socket =
      socket
      |> update_menus()
      |> assign(content_items: content_items)
      |> assign(next_best_action: NextAction.Public.next_best_action(url_resolver(socket), user))

    {:ok, socket}
  end

  def handle_info({:handle_auto_save_done, _}, socket) do
    socket |> update_menus()
    {:noreply, socket}
  end

  # data(content_items, :any)
  # data(current_user, :any)
  # data(next_best_action, :any)
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
        socket,
        %{
          promotion: %{
            title: title,
            subtitle: subtitle,
            image_id: image_id
          },
          promotable: %{
            assignable_experiment: %{
              data_donation_tool: %{
                id: edit_id
              }
            }
          }
        }
      ) do
    image_info = ImageHelpers.get_image_info(image_id, 120, 115)
    image = %{type: :catalog, info: image_info}

    %{
      path: Routes.live_path(socket, Systems.DataDonation.ContentPage, edit_id),
      title: title,
      subtitle: subtitle,
      tag: %{text: "Concept", type: :success},
      level: :critical,
      image: image
    }
  end
end
