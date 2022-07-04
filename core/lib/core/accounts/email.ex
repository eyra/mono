defmodule Core.Accounts.Email do
  use Bamboo.Phoenix, view: Core.Accounts.EmailView

  alias Systems.{
    Email
  }

  def mail_user(emails) when is_list(emails) do
    Email.Context.base_email() |> to(emails)
  end

  def mail_user(email) when is_binary(email) do
    Email.Context.base_email() |> to(email)
  end

  def mail_user(%{email: email} = user) do
    mail_user(email) |> assign(:user, user)
  end

  def account_confirmation_instructions(user, url) do
    mail_user(user)
    |> subject("Confirm your account")
    |> render(:account_confirmation_instructions, url: url)
  end

  def reset_password_instructions(user, url) do
    mail_user(user)
    |> subject("Password reset")
    |> render(:reset_password_instructions, url: url)
  end

  def update_email_instructions(user, url) do
    mail_user(user)
    |> subject("Update email")
    |> render(:update_email_instructions, url: url)
  end

  def already_activated_notification(user, url) do
    mail_user(user)
    |> subject("Already activated")
    |> render(:already_activated_notification, url: url)
  end

  def account_created(user) do
    mail_user(user)
    |> assign(:email_header_image, "welcome")
    |> subject("Welcome to Panl")
    |> render(:account_created)
  end

  def debug(subject, message, from_user, to_user) do
    mail_user(to_user)
    |> from(from_user.email)
    |> subject(subject)
    |> render(:debug_message, message: message, from_user: from_user, to_user: to_user)
  end

  def notification(title, byline, message, to) do
    text_message = message
    html_message = message |> to_html()

    mail_user(to)
    |> subject("Panl notification")
    |> render(:notification,
      title: title,
      byline: byline,
      text_message: text_message,
      html_message: html_message
    )
  end

  defp to_html(message) do
    message
    |> String.split("\n\n")
    |> Enum.map(&String.trim(&1))
    |> Enum.map(&String.replace(&1, "\n", "<br>"))
    |> Enum.filter(&(byte_size(&1) != 0))
    |> Enum.map_join(&"<p>#{&1}</p>")
  end
end
