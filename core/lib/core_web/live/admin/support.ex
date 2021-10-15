defmodule CoreWeb.Admin.Support do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :support

  alias Core.Helpdesk
  alias Core.Helpdesk.Ticket
  alias Core.ImageHelpers

  alias EyraUI.Text.{Title2}
  alias CoreWeb.UI.ContentListItem

  data(tickets, :any)

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> update_tickets()
      |> update_menus()
    }
  end

  defp update_tickets(socket) do
    socket
    |> assign(
      :tickets,
      Helpdesk.list_open_tickets()
      |> Enum.map(&to_view_model(&1, socket))
    )
  end

  defp to_view_model(
         %Ticket{
           id: id,
           updated_at: updated_at,
           title: title,
           user: %{
             profile: %{
               fullname: subtitle,
               photo_url: photo_url
             },
             features: %{
               gender: gender
             }
           }
         } = ticket,
         socket
       ) do
    quick_summery =
      updated_at
      |> CoreWeb.UI.Timestamp.apply_timezone()
      |> CoreWeb.UI.Timestamp.humanize()

    image = %{
      type: :avatar,
      info: ImageHelpers.get_photo_url(%{photo_url: photo_url, gender: gender})
    }

    %{
      path: Routes.live_path(socket, CoreWeb.Admin.Ticket, id),
      title: title,
      subtitle: subtitle,
      quick_summary: quick_summery,
      tag: Ticket.tag(ticket),
      image: image
    }
  end

  def render(assigns) do
    ~H"""
    <Workspace
      title={{ dgettext("eyra-admin", "support.title") }}
      menus={{ @menus }}
    >
      <ContentArea>
        <MarginY id={{:page_top}} />
        <Title2>{{ dgettext("eyra-admin", "support.tickets.title") }}</Title2>
        <ContentListItem :for={{item <- @tickets}} vm={{item}} />
      </ContentArea>
    </Workspace>
    """
  end
end
