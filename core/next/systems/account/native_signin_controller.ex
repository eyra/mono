defmodule Next.Account.NativeSigninController do
  @moduledoc """
  JSON calls behind the native Sign-in screen of the Next apps: identify
  (send a sign-in code to an email, or point to its identity provider), then
  verify the code; or redeem the token of an identity-provider sign-in (see
  `Next.Account.NativeHandoff`). They follow the participant
  path of the LiveView flow (`AuthIdentifyPage`, `AuthCodeVerifyPage`, the
  redeem step) and share its steps through `Next.Account.OtpSignin`.

  Verifying starts a mobile session and sets its cookie on the response;
  the body carries no credential. See the "Native sign-in" section of
  `docs/architecture/mobile/designs/authentication-session.md`.
  """
  use CoreWeb, {:controller, [formats: [:json]]}

  alias CoreWeb.ReturnTo
  alias Next.Account.NativeHandoff
  alias Next.Account.OtpSignin
  alias Systems.Account

  plug(Next.Account.NativeSigninGuard)

  @mobile_session %{mobile_session?: true}

  def identify(conn, %{"email" => email} = params) when is_binary(email) do
    with_otp(conn, fn ->
      email = String.trim(email)
      return_to = return_to(params)

      if OtpSignin.valid_email?(email) do
        route_email(conn, email, return_to)
      else
        error(conn, :unprocessable_entity, "invalid_email")
      end
    end)
  end

  def identify(conn, _params), do: error(conn, :bad_request, "invalid_request")

  def verify_code(conn, %{"email" => email, "code" => code} = params)
      when is_binary(email) and is_binary(code) do
    with_otp(conn, fn ->
      email = String.trim(email)

      case Account.Public.verify_otp(email, String.trim(code), client_ip(conn)) do
        {:ok, user} -> sign_in(conn, %{user_id: user && user.id, email: email}, return_to(params))
        {:error, :invalid} -> error(conn, :unprocessable_entity, "invalid_code")
        {:error, :not_found} -> error(conn, :unprocessable_entity, "code_expired")
        {:error, :max_attempts} -> error(conn, :unprocessable_entity, "too_many_attempts")
      end
    end)
  end

  def verify_code(conn, _params), do: error(conn, :bad_request, "invalid_request")

  @doc """
  Redeems the token an identity-provider sign-in in the sign-in sheet sent to
  the app's callback URL (`Next.Account.NativeHandoff`), with the code
  verifier of the challenge the app started it with.
  """
  def redeem(conn, %{"token" => token, "code_verifier" => code_verifier})
      when is_binary(token) and is_binary(code_verifier) do
    case NativeHandoff.redeem(token, code_verifier) do
      {:ok, user, first_time?, return_to} -> start_session(conn, user, first_time?, return_to)
      {:error, reason} -> error(conn, :unprocessable_entity, Atom.to_string(reason))
    end
  end

  def redeem(conn, _params), do: error(conn, :bad_request, "invalid_request")

  defp route_email(conn, email, return_to) do
    case Account.EmailRouter.route(email) do
      :otp ->
        case Account.Public.generate_otp(email, client_ip(conn)) do
          :ok -> respond(conn, %{next: "code"})
          {:error, :rate_limited} -> error(conn, :too_many_requests, "rate_limited")
        end

      provider when provider in [:google, :surfconext] ->
        respond(conn, %{
          next: "identity_provider",
          provider: provider,
          url: OtpSignin.provider_url(provider, email, return_to)
        })

      _provider_without_email_sign_in ->
        error(conn, :unprocessable_entity, "unsupported_account")
    end
  end

  defp sign_in(conn, payload, return_to) do
    case OtpSignin.resolve_user(conn.assigns[:current_user], Map.put(payload, :creator?, false)) do
      {:ok, user, first_time?} -> start_session(conn, user, first_time?, return_to)
      {:error, _changeset} -> error(conn, :unprocessable_entity, "invalid_email")
    end
  end

  defp start_session(conn, user, first_time?, return_to) do
    conn
    |> Account.UserAuth.log_in_user_without_redirect(user, @mobile_session)
    |> respond(%{onboarding: first_time?, redirect_to: redirect_to(first_time?, return_to)})
  end

  defp redirect_to(true, return_to), do: ReturnTo.append(~p"/user/onboarding", return_to)
  defp redirect_to(false, return_to), do: return_to

  # The client's address from CoreWeb.Plug.RemoteIp; the sign-in code limits
  # count by it.
  defp client_ip(%Plug.Conn{remote_ip: remote_ip}), do: remote_ip |> :inet.ntoa() |> to_string()

  defp return_to(%{"return_to" => return_to}), do: ReturnTo.sanitize(return_to)
  defp return_to(_params), do: nil

  defp with_otp(conn, fun) do
    if feature_enabled?(:otp), do: fun.(), else: error(conn, :not_found, "unavailable")
  end

  defp error(conn, status, error) do
    conn
    |> put_status(status)
    |> respond(%{error: error})
  end

  defp respond(conn, body) do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> json(body)
  end
end
