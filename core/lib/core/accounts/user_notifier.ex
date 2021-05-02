defmodule Core.Accounts.UserNotifier do
  alias Core.Accounts.Email

  defp deliver_later(email) do
    Core.Mailer.deliver_later(email)
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    Email.account_confirmation_instructions(user, url)
    |> deliver_later()
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    Email.reset_password_instructions(user, url)
    |> deliver_later()
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    Email.update_email_instructions(user, url)
    |> deliver_later()
  end

  @doc """
  Deliver instructions to users that are already activated.
  """
  def deliver_already_activated_notification(user, url) do
    Email.already_activated_notification(user, url)
    |> deliver_later()
  end
end
