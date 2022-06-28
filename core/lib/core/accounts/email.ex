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

  def debug(subject, body, from_user, to_user) do
    mail_user(to_user)
    |> from(from_user.email)
    |> subject(subject)
    |> render(:debug_message, body: body, from_user: from_user, to_user: to_user)
  end

  def admin(subject, body, from, to) when is_binary(from) do
    mail_user(to)
    |> from(from)
    |> subject(subject)
    |> render(:admin_message, body: body)
  end
end
