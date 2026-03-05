defmodule Core.WebPush.SignalHandlers do
  @moduledoc false
  use Core, :auth
  use Frameworks.Signal.Handler

  alias Core.WebPush
  alias Systems.Notification.Box

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
