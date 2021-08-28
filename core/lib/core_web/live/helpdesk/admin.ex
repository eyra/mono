defmodule CoreWeb.Helpdesk.Admin do
  use CoreWeb, :live_view
  alias Core.Helpdesk

  data(tickets, :any)

  def mount(_params, _session, socket) do
    {
      :ok,
      socket |> assign(:tickets, Helpdesk.list_open_tickets())
    }
  end

  def handle_event("close_ticket", %{"id" => id}, socket) do
    Helpdesk.close_ticket_by_id(id)
    {:noreply, socket |> assign(:tickets, Helpdesk.list_open_tickets())}
  end

  def render(assigns) do
    ~H"""
    <div>
      Admin
      <div :for={{ticket <- @tickets}}>
        <h1>{{ticket.title}}</h1>
        <p>{{ticket.description}}</p>
        <p>
        <a href="mailto:{{ticket.user.email}}">Contact {{ticket.user.email}}</a>
        </p>
        <button :on-click="close_ticket" phx-value-id={{ticket.id}}>Close ticket</button>
      </div>
    </div>
    """
  end
end
