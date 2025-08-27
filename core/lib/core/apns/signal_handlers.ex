defmodule Core.APNS.SignalHandlers do
  use Core, :auth
  use Frameworks.Signal.Handler
  use Bamboo.Phoenix, template: Systems.Email.EmailHTML
  import Core.APNS, only: [send_notification: 2]

  @impl true
  def intercept(:new_notification, %{box: box, data: %{title: title}}) do
    for user <- auth_module().users_with_role(box, :owner) do
      send_notification(user, title)
    end

    :ok
  end
end
