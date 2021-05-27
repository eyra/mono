defmodule Core.Mailer.SignalHandlers do
  use Core.Signals.Handlers
  use Bamboo.Phoenix, view: Core.Mailer.EmailView
  import Core.Mailer, only: [base_email: 0, deliver_later: 1]
  alias Core.NotificationCenter.Box

  @impl true
  def dispatch(:new_notification, %{box: box, data: %{title: title}}) do
    for mail <- mail_users(box) do
      mail
      |> subject(title)
      |> render(:new_notification, title: title)
      |> deliver_later()
    end
  end

  defp mail_users(%Box{} = box) do
    box
    |> Core.Authorization.users_with_role(:owner)
    |> Enum.map(&user_email(&1))
  end

  defp user_email(user) do
    base_email() |> to(user.email) |> assign(:user, user)
  end
end
