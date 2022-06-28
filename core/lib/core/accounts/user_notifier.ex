defmodule Core.Accounts.UserNotifier do
  alias Core.Accounts

  alias Systems.{
    Email
  }

  defp deliver_later(email) do
    Email.Context.deliver_later(email)
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    Accounts.Email.account_confirmation_instructions(user, url)
    |> deliver_later()
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    Accounts.Email.reset_password_instructions(user, url)
    |> deliver_later()
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    Accounts.Email.update_email_instructions(user, url)
    |> deliver_later()
  end

  @doc """
  Deliver instructions to users that are already activated.
  """
  def deliver_already_activated_notification(user, url) do
    Accounts.Email.already_activated_notification(user, url)
    |> deliver_later()
  end
end
