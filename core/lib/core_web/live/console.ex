defmodule CoreWeb.Console do
  @moduledoc """
  The console screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :console

  alias CoreWeb.UI.ContentList

  alias Systems.{
    Campaign,
    NextAction
  }

  alias Frameworks.Pixel.Text.{Title2}
  alias Core.ImageHelpers

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  data(content_items, :any)
  data(current_user, :any)
  data(next_best_action, :any)

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    preload = Campaign.Model.preload_graph(:full)

    # FIXME: Refactor to use content node
    content_items =
      user
      |> Campaign.Context.list_owned_campaigns(preload: preload)
      |> Enum.map(&Campaign.Model.flatten(&1))
      |> Enum.map(&convert_to_vm(socket, &1))

    socket =
      socket
      |> update_menus()
      |> assign(content_items: content_items)
      |> assign(next_best_action: NextAction.Context.next_best_action(url_resolver(socket), user))

    {:ok, socket}
  end

  def handle_info({:handle_auto_save_done, _}, socket) do
    socket |> update_menus()
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <Workspace title={dgettext("eyra-ui", "dashboard.title")} menus={@menus}>
      <ContentArea>
        <MarginY id={:page_top} />
        <div :if={@next_best_action}>
          <NextAction.HighlightView vm={@next_best_action} />
          <Spacing value="XL" />
        </div>
        <Title2>
          {dgettext("eyra-dashboard", "recent-items.title")}
        </Title2>
        <ContentList items={@content_items} />
      </ContentArea>
    </Workspace>
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
