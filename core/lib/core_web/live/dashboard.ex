defmodule CoreWeb.Dashboard do
  @moduledoc """
  The dashboard screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :dashboard

  alias Core.Studies
  alias CoreWeb.UI.ContentListItem

  alias EyraUI.Text.{Title2}
  alias Core.NextActions.Live.NextActionHighlight
  alias Core.NextActions
  alias Core.ImageHelpers

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  data(content_items, :any)
  data(current_user, :any)
  data(next_best_action, :any)

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    preload = [data_donation_tool: [:promotion]]

    # FIXME: Refactor to use content node
    content_items =
      user
      |> Studies.list_owned_studies(preload: preload)
      |> Enum.map(&convert_to_vm(socket, &1))

    socket =
      socket
      |> update_menus()
      |> assign(content_items: content_items)
      |> assign(next_best_action: NextActions.next_best_action(url_resolver(socket), user))

    {:ok, socket}
  end

  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  def render(assigns) do
    ~H"""
      <Workspace
        title={{ dgettext("eyra-ui", "dashboard.title") }}
        menus={{ @menus }}
      >
        <ContentArea>
          <MarginY id={{:page_top}} />
            <div :if={{ @next_best_action }}>
              <NextActionHighlight vm={{ @next_best_action }}/>
              <Spacing value="XL" />
            </div>
            <Title2>
              {{ dgettext("eyra-dashboard", "recent-items.title") }}
            </Title2>
            <ContentListItem :for={{item <- @content_items}} vm={{item}} />
        </ContentArea>
    </Workspace>
    """
  end

  def convert_to_vm(socket, %{
        data_donation_tool: %{
          id: edit_id,
          promotion: %{
            title: title,
            subtitle: subtitle,
            image_id: image_id
          }
        }
      }) do
    image_info = ImageHelpers.get_image_info(image_id, 120, 115)
    image = %{type: :catalog, info: image_info}

    %{
      path: Routes.live_path(socket, CoreWeb.DataDonation.Content, edit_id),
      title: title,
      subtitle: subtitle,
      tag: %{text: "Concept", type: :success},
      level: :critical,
      image: image
    }
  end
end
