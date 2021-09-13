defmodule CoreWeb.Admin.Ticket do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :ticket
  use CoreWeb.UI.Dialog

  alias Core.Helpdesk
  alias Core.Helpdesk.Ticket

  alias EyraUI.Wrap
  alias EyraUI.Text.Title2
  alias EyraUI.Button.Face.Secondary
  alias EyraUI.Button.Action.Send
  alias EyraUI.Line
  alias CoreWeb.UI.{Member, ContentTag}

  data(ticket, :any)
  data(timestamp, :any)
  data(member, :any, default: nil)

  def mount(%{"id" => id}, _session, socket) do
    ticket = Helpdesk.get_ticket!(id)

    timestamp =
      ticket.updated_at
      |> Coreweb.UI.Timestamp.apply_timezone()
      |> Coreweb.UI.Timestamp.humanize()

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(ticket: ticket)
      |> assign(timestamp: timestamp)
      |> assign(dialog: nil)
      |> update_member()
      |> update_menus(id)
    }
  end

  defp update_member(%{assigns: %{ticket: ticket}} = socket) do
    socket
    |> assign(member: to_member(ticket))
  end

  defp to_member(%{
         id: id,
         title: title,
         user: %{
           email: email,
           researcher: researcher,
           student: student,
           coordinator: coordinator,
           profile: %{
             fullname: fullname,
             photo_url: photo_url
           }
         }
       }) do
    role =
      cond do
        coordinator -> dgettext("eyra-admin", "role.coordinator")
        researcher -> dgettext("eyra-admin", "role.researcher")
        student -> dgettext("eyra-admin", "role.student")
        true -> nil
      end

    %{
      title: fullname,
      subtitle: role,
      photo_url: photo_url,
      button: %{
        action: %{type: :href, href: "mailto:#{email}?subject=Re: [##{id}] #{title}"},
        face: %{type: :primary, label: dgettext("eyra-admin", "ticket.mailto.button")}
      }
    }
  end

  def handle_event("close_ticket", _params, socket) do
    item = dgettext("eyra-admin", "close.confirm.ticket")
    title = String.capitalize(dgettext("eyra-ui", "close.confirm.title", item: item))
    text = String.capitalize(dgettext("eyra-ui", "close.confirm.text", item: item))
    confirm_label = dgettext("eyra-ui", "close.confirm.label")

    {:noreply, socket |> confirm("close", title, text, confirm_label)}
  end

  def handle_event("close_confirm", _params, %{assigns: %{id: id}} = socket) do
    Helpdesk.close_ticket_by_id(id)
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, CoreWeb.Admin.Support))}
  end

  def handle_event("close_cancel", _params, socket) do
    {:noreply, socket |> assign(dialog: nil)}
  end

  defp show_dialog?(nil), do: false
  defp show_dialog?(_), do: true

  def render(assigns) do
    ~H"""
    <Workspace
      title={{ dgettext("eyra-admin", "ticket.title") }}
      menus={{ @menus }}
    >
      <div :if={{ show_dialog?(@dialog) }} class="fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-20">
        <div class="flex flex-row items-center justify-center w-full h-full">
          <Dialog vm={{ @dialog }} />
        </div>
      </div>
      <ContentArea>
        <MarginY id={{:page_top}} />
        <Member :if={{ @member }} vm={{ @member }} />
        <MarginY id={{:page_top}} />
        <Line />
        <Spacing value="M" />
        <div class="flex flex-row gap-4 items-center">
          <Wrap>
            <ContentTag vm={{ Ticket.tag(@ticket) }} />
          </Wrap>
          <div class="text-label font-label text-grey1">
            #{{ @ticket.id }}
          </div>
          <div class="text-label font-label text-grey2">
            {{ @timestamp }}
          </div>
        </div>
        <Spacing value="S" />
        <Title2>{{ @ticket.title }}</Title2>
        <div class="text-bodymedium sm:text-bodylarge font-body mb-6 md:mb-8 lg:mb-10">{{ @ticket.description }}</div>
        <Wrap>
          <Send vm={{ %{event: "close_ticket" } }}>
            <Secondary vm={{ label: dgettext("eyra-admin", "close.ticket.button"), text_color: "text-delete" }} />
          </Send>
        </Wrap>
      </ContentArea>
      <MarginY id={{:page_footer_top}} />
    </Workspace>
    """
  end
end
