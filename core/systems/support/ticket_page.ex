defmodule Systems.Support.TicketPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :ticket

  alias Systems.{
    Support
  }

  import CoreWeb.UI.Member
  alias Frameworks.Pixel.Text
  import CoreWeb.UI.Content

  def mount(%{"id" => id}, _session, socket) do
    ticket = Support.Public.get_ticket!(id)

    timestamp =
      ticket.updated_at
      |> CoreWeb.UI.Timestamp.apply_timezone()
      |> CoreWeb.UI.Timestamp.humanize()

    {
      :ok,
      socket
      |> assign(
        id: id,
        ticket: ticket,
        timestamp: timestamp,
        member: nil
      )
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

    action = %{type: :http_get, to: "mailto:#{email}?subject=Re: [##{id}] #{title}"}

    %{
      title: fullname,
      subtitle: role,
      photo_url: photo_url,
      gender: gender,
      button_large: %{
        action: action,
        face: %{
          type: :primary,
          label: dgettext("eyra-ui", "mailto.button"),
          bg_color: "bg-tertiary",
          text_color: "text-grey1"
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
    Support.Public.close_ticket_by_id(id)
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, Systems.Support.OverviewPage))}
  end

  @impl true
  def handle_event("reopen_ticket", _params, %{assigns: %{id: id}} = socket) do
    Support.Public.reopen_ticket_by_id(id)
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

  @impl true
  def render(assigns) do
    ~H"""
    <.workspace title={dgettext("eyra-admin", "ticket.title")} menus={@menus}>
      <Area.content>
        <Margin.y id={:page_top} />
        <%= if @member do %>
          <.member {@member} />
        <% end %>
        <Margin.y id={:page_top} />
        <div class="flex flex-row gap-4 items-center">
          <.wrap>
            <.tag {Support.TicketModel.tag(@ticket)} />
          </.wrap>
          <div class="text-label font-label text-grey1">
            #<%= @ticket.id %>
          </div>
          <div class="text-label font-label text-grey2">
            <%= @timestamp %>
          </div>
        </div>
        <.spacing value="S" />
        <Text.title2><%= @ticket.title %></Text.title2>
        <div class="text-bodymedium sm:text-bodylarge font-body mb-6 md:mb-8 lg:mb-10"><%=@ticket.description %></div>
        <.wrap>
          <Button.dynamic {button(assigns)} />
        </.wrap>
      </Area.content>
    </.workspace>
    """
  end
end
