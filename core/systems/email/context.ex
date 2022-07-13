defmodule Systems.Email.Context do
  import Bamboo.Email
  import Bamboo.Phoenix

  alias Core.Accounts

  alias Systems.{
    Email
  }

  def base_email do
    new_email()
    |> from(
      Application.fetch_env!(:core, Systems.Email.Mailer)
      |> Keyword.fetch!(:default_from_email)
    )
    |> put_layout({Systems.Email.EmailLayoutView, :email})
    |> assign(:email_header_image, "notification")
  end

  def deliver_later!(%Email.Model{} = email), do: dispatch(email)
  def deliver_later!(email), do: Email.Mailer.deliver_later!(email)
  def deliver_later(email), do: Email.Mailer.deliver_later(email)

  def deliver_now!(%Email.Model{
        title: title,
        byline: byline,
        message: message,
        to: to
      }) do
    Accounts.Email.notification(title, byline, message, to)
    |> deliver_now!()
  end

  def deliver_now!(email), do: Email.Mailer.deliver_now!(email)

  def deliver_now(%Email.Model{title: title, byline: byline, message: message, to: to}) do
    Accounts.Email.notification(title, byline, message, to)
    |> deliver_now()
  end

  def deliver_now(email), do: Email.Mailer.deliver_now(email)

  defp dispatch(email) when is_struct(email) do
    email
    |> Email.Dispatcher.new()
    |> Oban.insert()
  end
end
