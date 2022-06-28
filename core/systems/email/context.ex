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

  def deliver_later(%Email.Model{subject: subject, message: message, from: from, to: to}) do
    Accounts.Email.admin(subject, message, from, to)
    |> deliver_later()
  end

  def deliver_later(email) do
    Email.Mailer.deliver_later(email)
  end

  def deliver_now!(%Email.Model{subject: subject, message: message, from: from, to: to}) do
    Accounts.Email.admin(subject, message, from, to)
    |> deliver_now!()
  end

  def deliver_now!(email) do
    Email.Mailer.deliver_now!(email)
  end
end
