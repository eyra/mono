defmodule Systems.Notification.OverviewPage do
  use CoreWeb, :live_view
  alias Systems.Notification

  data(notifications, :any)

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    {:ok, socket |> assign(:notifications, Notification.Context.list(user))}
  end

  @impl true
  def handle_uri(socket), do: socket

  def render(assigns) do
    ~F"""
    <div>
    Notifications
    <ul>
    <li :for={notification <- @notifications}>
      {notification.title}
    </li>
    </ul>
    </div>
    """
  end
end
