defmodule CoreWeb.Dashboard do
  @moduledoc """
  The dashboard screen.
  """
  use CoreWeb, :live_view

  alias Core.Studies
  alias CoreWeb.Components.ContentListItem

  alias EyraUI.Hero.HeroSmall
  alias EyraUI.Container.{ContentArea}
  alias EyraUI.Text.{Title2}

  data(content_items, :any)
  data(current_user, :any)

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    preload = [data_donation_tool: [:promotion]]

    # FIXME: Refactor to use content node
    content_items =
      user
      |> Studies.list_owned_studies(preload: preload)
      |> Enum.map(&convert_to_vm(socket, &1))

    socket =
      socket
      |> assign(content_items: content_items)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
      <HeroSmall title={{ dgettext("eyra-dashboard", "title") }} />
      <ContentArea>
        <Title2>
          {{ dgettext("eyra-marketplace", "recent-items.title") }}
        </Title2>
        <ContentListItem :for={{item <- @content_items}} title={{item.title}} description="Facere dolorem sequi sit voluptas labore porro qui quis" type="Studie" status={{item.status}} level={{:critical}} image_id={{item.image_id}} to={{item.path}}  />
      </ContentArea>
    """
  end

  def convert_to_vm(socket, %{
        data_donation_tool: %{
          id: edit_id,
          promotion: %{
            title: title,
            description: description,
            image_id: image_id
          }
        }
      }) do
    %{
      path: Routes.live_path(socket, CoreWeb.DataDonation.Content, edit_id),
      title: title,
      description: description,
      status: %{label: "Concept", color: "success"},
      level: :critical,
      image_id: image_id
    }
  end
end
