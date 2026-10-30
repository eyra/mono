defmodule Next.Systems.Account.NativeHandoff do
  @moduledoc """
  Hands a sign-in through an identity provider back to the Next native apps.

  The app opens the provider in the system sign-in sheet, which keeps its own
  cookies. `NativeProviderController.start/2` marks the sheet with a cookie
  that holds the provider and the app's code challenge. When that provider's
  flow signs the user in, `hand_off/4` redirects the sheet to the app's
  callback URL with a one-time token instead of starting a session there; when
  it ends without signing in, `hand_off_unfinished/3` sends the result there.
  Other sign-ins in the same browser are left alone. The app redeems the token
  in its own web view (`NativeSigninController.redeem/2`) together with the
  code verifier.

  See the "Identity providers in the sign-in sheet" section of
  `docs/architecture/mobile/designs/authentication-session.md`.
  """
  @behaviour Systems.Account.SignInHandoff

  import Plug.Conn

  alias MicaWeb.Endpoint
  alias Systems.Account

  @cookie "_next_native_sign_in"
  @cookie_max_age 10 * 60
  @token_context "native_sign_in"
  @token_salt "native-sign-in"
  @token_max_age 2 * 60
  @code_challenge ~r/\A[A-Za-z0-9_-]{43}\z/

  @doc "Whether `code_challenge` is a Base64url SHA-256 digest, as `S256` sends it."
  def valid_code_challenge?(code_challenge) when is_binary(code_challenge),
    do: Regex.match?(@code_challenge, code_challenge)

  def valid_code_challenge?(_code_challenge), do: false

  @doc "Marks the sheet: the next sign-in through `provider` in it goes back to the app."
  def start(conn, provider, code_challenge, return_to) when is_binary(provider) do
    marker = %{provider: provider, code_challenge: code_challenge, return_to: return_to}

    put_resp_cookie(conn, @cookie, marker,
      sign: true,
      max_age: @cookie_max_age,
      http_only: true,
      same_site: "Lax"
    )
  end

  @impl Systems.Account.SignInHandoff
  def hand_off(conn, provider, user, first_time?) do
    case pending(conn, provider) do
      %{code_challenge: code_challenge, return_to: return_to} ->
        token = issue(user, first_time?, code_challenge, return_to)

        # The sheet keeps no session: the app's web view gets one when it redeems.
        conn =
          conn
          |> configure_session(drop: true)
          |> return_to_app(token: token)

        {:ok, conn}

      nil ->
        :skip
    end
  end

  @impl Systems.Account.SignInHandoff
  def hand_off_unfinished(conn, provider, result) do
    case pending(conn, provider) do
      %{} -> {:ok, return_to_app(conn, error: Atom.to_string(result))}
      nil -> :skip
    end
  end

  @doc "Sends the sheet back to the app with an `error` instead of a token."
  def return_error(conn, error), do: return_to_app(conn, error: error)

  @doc """
  The app's callback URL, on Mica's own host; the sheet catches it before it
  loads.
  """
  def callback_url(params),
    do: "#{Endpoint.url()}/user/auth/native/callback?#{URI.encode_query(params)}"

  @doc """
  Redeems a token of `hand_off/4` with the app's code verifier. The token is
  used up by the first attempt, whether the verifier matches or not.
  """
  def redeem(token, code_verifier) when is_binary(token) and is_binary(code_verifier) do
    with {:ok, %{first_time?: first_time?, return_to: return_to} = payload} <- decrypt(token),
         {:ok, user} <- take(payload),
         :ok <- verify(payload, code_verifier) do
      {:ok, user, first_time?, return_to}
    end
  end

  defp issue(user, first_time?, code_challenge, return_to) do
    Phoenix.Token.encrypt(Endpoint, @token_salt, %{
      token: Account.Public.generate_one_time_token(user, @token_context),
      first_time?: first_time?,
      code_challenge: code_challenge,
      return_to: return_to
    })
  end

  defp decrypt(token) do
    case Phoenix.Token.decrypt(Endpoint, @token_salt, token, max_age: @token_max_age) do
      {:ok, payload} -> {:ok, payload}
      {:error, :expired} -> {:error, :token_expired}
      {:error, _reason} -> {:error, :invalid_token}
    end
  end

  defp take(%{token: token}) do
    case Account.Public.take_one_time_token(token, @token_context, @token_max_age) do
      {:ok, user} -> {:ok, user}
      {:error, :not_found} -> {:error, :token_used}
    end
  end

  defp verify(%{code_challenge: code_challenge}, code_verifier) do
    digest = :crypto.hash(:sha256, code_verifier) |> Base.url_encode64(padding: false)

    if Plug.Crypto.secure_compare(digest, code_challenge),
      do: :ok,
      else: {:error, :verifier_mismatch}
  end

  defp return_to_app(conn, params) do
    conn
    |> delete_resp_cookie(@cookie, http_only: true, same_site: "Lax")
    |> put_resp_header("cache-control", "no-store")
    |> Phoenix.Controller.redirect(external: callback_url(params))
  end

  # The marker of a sheet that `start/4` marked for `provider`, or nil.
  defp pending(conn, provider) do
    provider = Atom.to_string(provider)

    case conn |> fetch_cookies(signed: [@cookie]) |> Map.fetch!(:cookies) |> Map.get(@cookie) do
      %{provider: ^provider} = marker -> marker
      _ -> nil
    end
  end
end
