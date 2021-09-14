defmodule Core.Accounts.Email do
  use Bamboo.Phoenix, view: Core.Accounts.EmailView
  import Core.Mailer, only: [base_email: 0]

  def mail_user(user) do
    base_email() |> to(user.email) |> assign(:user, user)
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
end
