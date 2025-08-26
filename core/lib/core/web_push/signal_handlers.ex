defmodule Core.WebPush.SignalHandlers do
  use Core, :auth
  use Frameworks.Signal.Handler
  alias Systems.Notification.Box
  alias Core.WebPush

  @impl true
  def intercept(:new_notification, %{box: box, data: %{title: title}}) do
    for user <- users(box) do
      :ok = WebPush.send(user, title)
    end

    :ok
  end

  defp users(%Box{} = box) do
    auth_module().users_with_role(box, :owner)
  end
end
