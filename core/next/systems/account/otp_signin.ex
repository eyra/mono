defmodule Next.Account.OtpSignin do
  @moduledoc """
  Steps of the email-first OTP sign-in shared by the LiveView pages
  (`AuthIdentifyPage`, `AuthCodeVerifyPage` and the redeem step in
  `SessionController`) and the native app's JSON calls
  (`NativeSigninController`), so both follow the same rules.
  """

  alias CoreWeb.ReturnTo
  alias Systems.Account

  def valid_email?(email), do: String.match?(email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/)

  @doc """
  Where an email that `Account.EmailRouter` sends to an identity provider
  continues signing in.
  """
  def provider_url(:google, email, return_to),
    do: ReturnTo.append("/auth/google?login_hint=#{URI.encode_www_form(email)}", return_to)

  def provider_url(:surfconext, _email, return_to),
    do: ReturnTo.append("/auth/surfconext", return_to)

  def provider_url(:mock, email, _return_to), do: "/auth/mock/callback?email=#{URI.encode(email)}"

  @doc """
  Finds or creates the user behind a verified code. `user_id` is the user the
  code was issued to, or nil when the email had no user yet.

  A new email normally registers a fresh user. When a provisional user (an
  affiliate synth account that never had a real email) is signed in, the
  email is linked to that user instead, so completing auth from the
  finished-page "Join Panl" CTA doesn't leave a duplicate user behind.

  Returns `{:ok, user, first_time?}`; `first_time?` is true for a newly
  registered user, who still has to go through onboarding.
  """
  def resolve_user(_current_user, %{user_id: user_id}) when not is_nil(user_id),
    do: {:ok, Account.Public.get_user!(user_id), false}

  def resolve_user(%Account.User{} = current_user, %{email: email} = payload) do
    with true <- Account.Auth.Email.provisional?(current_user),
         {:ok, linked_user} <- Account.Auth.Email.link(current_user, email) do
      {:ok, linked_user, false}
    else
      _ -> register(payload)
    end
  end

  def resolve_user(_current_user, payload), do: register(payload)

  defp register(%{email: email} = payload) do
    case Account.Public.register_user_with_email(email, Map.get(payload, :creator?, false)) do
      {:ok, user} -> {:ok, user, true}
      {:error, _changeset} = error -> error
    end
  end
end
