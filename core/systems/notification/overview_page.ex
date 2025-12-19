defmodule Systems.Notification.OverviewPage do
  use CoreWeb, :live_view
  alias Systems.Notification

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    {:ok, socket |> assign(:notifications, Notification.Public.list(user))}
  end

  # data(notifications, :any)
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      Notifications
      <ul>
        <%= for notification <- @notifications do %>
          <li>
            <%= notification.title %>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end
