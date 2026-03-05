defmodule Systems.Account.UserNotifier do
  @moduledoc false
  alias Systems.Email

  defp deliver_later(email) do
    Email.Public.deliver_later(email)
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    user
    |> Email.Factory.account_confirmation_instructions(url)
    |> deliver_later()
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    user
    |> Email.Factory.reset_password_instructions(url)
    |> deliver_later()
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    user
    |> Email.Factory.update_email_instructions(url)
    |> deliver_later()
  end

  @doc """
  Deliver instructions to users that are already activated.
  """
  def deliver_already_activated_notification(user, url) do
    user
    |> Email.Factory.already_activated_notification(url)
    |> deliver_later()
  end
end
