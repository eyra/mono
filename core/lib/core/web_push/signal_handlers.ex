defmodule Core.WebPush.SignalHandlers do
  use Core.Signals.Handlers
  alias Systems.Notification.Box
  alias Core.WebPush

  @impl true
  def dispatch(:new_notification, %{box: box, data: %{title: title}}) do
    for user <- users(box) do
      :ok = WebPush.send(user, title)
    end
  end

  defp users(%Box{} = box) do
    Core.Authorization.users_with_role(box, :owner)
  end
end
