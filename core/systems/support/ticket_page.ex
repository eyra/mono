defmodule Systems.Support.TicketPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :ticket

  alias Systems.{
    Support
  }

  alias Frameworks.Pixel.Wrap
  alias Frameworks.Pixel.Text.Title2
  alias CoreWeb.UI.{Member, ContentTag}

  data(ticket, :any)
  data(timestamp, :any)
  data(member, :any, default: nil)

  def mount(%{"id" => id}, _session, socket) do
    ticket = Support.Context.get_ticket!(id)

    timestamp =
      ticket.updated_at
      |> CoreWeb.UI.Timestamp.apply_timezone()
      |> CoreWeb.UI.Timestamp.humanize()

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(ticket: ticket)
      |> assign(timestamp: timestamp)
      |> update_member()
      |> update_menus()
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
           },
           features: %{
             gender: gender
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

    action = %{type: :href, href: "mailto:#{email}?subject=Re: [##{id}] #{title}"}

    %{
      title: fullname,
      subtitle: role,
      photo_url: photo_url,
      gender: gender,
      button_large: %{
        action: action,
        face: %{
          type: :secondary,
          label: dgettext("eyra-admin", "ticket.mailto.button"),
          border_color: "border-white",
          text_color: "text-white"
        }
      },
      button_small: %{
        action: action,
        face: %{type: :icon, icon: :contact_tertiary}
      }
    }
  end

  @impl true
  def handle_event("close_ticket", _params, %{assigns: %{id: id}} = socket) do
    Support.Context.close_ticket_by_id(id)
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, Systems.Support.OverviewPage))}
  end

  @impl true
  def handle_event("reopen_ticket", _params, %{assigns: %{id: id}} = socket) do
    Support.Context.reopen_ticket_by_id(id)
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, Systems.Support.OverviewPage))}
  end

  defp button(%{ticket: %{completed_at: completed_at}}) when is_nil(completed_at) do
    %{
      action: %{type: :send, event: "close_ticket"},
      face: %{
        type: :secondary,
        label: dgettext("eyra-admin", "close.ticket.button"),
        text_color: "text-delete"
      }
    }
  end

  defp button(_) do
    %{
      action: %{type: :send, event: "reopen_ticket"},
      face: %{
        type: :secondary,
        label: dgettext("eyra-admin", "reopen.ticket.button"),
        text_color: "text-primary"
      }
    }
  end

  def render(assigns) do
    ~F"""
    <Workspace title={dgettext("eyra-admin", "ticket.title")} menus={@menus}>
      <ContentArea>
        <MarginY id={:page_top} />
        <Member :if={@member} vm={@member} />
        <MarginY id={:page_top} />
        <div class="flex flex-row gap-4 items-center">
          <Wrap>
            <ContentTag vm={Support.TicketModel.tag(@ticket)} />
          </Wrap>
          <div class="text-label font-label text-grey1">
            #{@ticket.id}
          </div>
          <div class="text-label font-label text-grey2">
            {@timestamp}
          </div>
        </div>
        <Spacing value="S" />
        <Title2>{@ticket.title}</Title2>
        <div class="text-bodymedium sm:text-bodylarge font-body mb-6 md:mb-8 lg:mb-10">{@ticket.description}</div>
        <Wrap>
          <DynamicButton vm={button(assigns)} />
        </Wrap>
      </ContentArea>
    </Workspace>
    """
  end
end
