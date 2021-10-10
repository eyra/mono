defmodule CoreWeb.Notifications do
  use CoreWeb, :live_view
  alias Systems.NotificationCenter

  data(notifications, :any)

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    {:ok, socket |> assign(:notifications, NotificationCenter.list(user))}
  end

  @impl true
  def handle_uri(socket), do: socket

  def render(assigns) do
    ~H"""
    <div>
    Notifications
    <ul>
    <li :for={{ notification <- @notifications }}>
      {{ notification.title }}
    </li>
    </ul>
    </div>
    """
  end
end
