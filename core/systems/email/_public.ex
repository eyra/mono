defmodule Systems.Email.Public do
  use Core, :public
  import Bamboo.Email
  import Bamboo.Phoenix

  alias Systems.{
    Email
  }

  def base_email do
    new_email()
    |> from(
      Application.fetch_env!(:core, Systems.Email.Mailer)
      |> Keyword.fetch!(:default_from_email)
    )
    |> put_layout({Systems.Email.EmailLayoutHTML, :email})
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
    Email.Factory.notification(title, byline, message, to)
    |> deliver_now!()
  end

  def deliver_now!(email), do: Email.Mailer.deliver_now!(email)

  def deliver_now(%Email.Model{title: title, byline: byline, message: message, to: to}) do
    Email.Factory.notification(title, byline, message, to)
    |> deliver_now()
  end

  def deliver_now(email), do: Email.Mailer.deliver_now(email)

  defp dispatch(email) when is_struct(email) do
    email
    |> Email.Dispatcher.new()
    |> Oban.insert()
  end
end
