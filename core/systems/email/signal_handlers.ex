defmodule Core.Mailer.SignalHandlers do
  use Core, :auth
  use Frameworks.Signal.Handler
  use Bamboo.Phoenix, template: Systems.Email.EmailHTML
  import Core.FeatureFlags
  alias Systems.Email
  alias Systems.Notification.Box

  @impl true
  def intercept(:new_notification, %{box: box, data: %{title: title}}) do
    if feature_enabled?(:notification_mails) do
      for mail <- base_emails(box) do
        mail
        |> subject(title)
        |> render(:new_notification, title: title)
        |> Email.Public.deliver_later()
      end
    end

    :ok
  end

  defp base_emails(%Box{} = box) do
    box
    |> auth_module().users_with_role(:owner)
    |> Enum.map(&user_email(&1))
  end

  defp user_email(user) do
    Email.Public.base_email() |> to(user.email) |> assign(:user, user)
  end
end
