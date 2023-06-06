defmodule Core.APNS.SignalHandlers do
  use Frameworks.Signal.Handler
  use Bamboo.Phoenix, component: Systems.Email.EmailHTML
  import Core.APNS, only: [send_notification: 2]

  @impl true
  def dispatch(:new_notification, %{box: box, data: %{title: title}}) do
    for user <- Core.Authorization.users_with_role(box, :owner) do
      send_notification(user, title)
    end
  end
end
