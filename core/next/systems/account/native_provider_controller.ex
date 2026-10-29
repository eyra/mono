defmodule Next.Account.NativeProviderController do
  @moduledoc """
  The pages the Next native apps open in the system sign-in sheet to sign in
  through an identity provider; see `Next.Account.NativeHandoff`.
  """
  use CoreWeb, {:controller, [formats: [:html]]}

  alias CoreWeb.ReturnTo
  alias Next.Account.NativeHandoff
  alias Systems.Account.Auth.Methods

  @doc """
  Marks the sheet with the app's code challenge and continues at Core's own
  start of the provider. `login_hint` preselects the account where the
  provider supports it; `return_to` comes back from the redeem.
  """
  def start(
        conn,
        %{"provider" => provider, "code_challenge" => code_challenge} = params
      ) do
    with "S256" <- params["code_challenge_method"],
         true <- NativeHandoff.valid_code_challenge?(code_challenge),
         {:ok, path} <- provider_path(provider, params["login_hint"]) do
      conn
      |> NativeHandoff.start(code_challenge, return_to(params))
      |> redirect(to: path)
    else
      :unavailable -> NativeHandoff.return_error(conn, "unavailable")
      _ -> NativeHandoff.return_error(conn, "invalid_request")
    end
  end

  def start(conn, _params), do: NativeHandoff.return_error(conn, "invalid_request")

  @doc """
  The app's callback URL. The sheet catches it before it loads, so a browser
  only gets here when it opens the link itself.
  """
  def callback(conn, _params), do: redirect(conn, to: ~p"/user/signin")

  defp provider_path("google", login_hint) do
    if Methods.provider?(:google) and feature_enabled?(:member_google_sign_in),
      do: {:ok, with_login_hint("/auth/google", login_hint)},
      else: :unavailable
  end

  defp provider_path("surfconext", _login_hint) do
    if Methods.provider?(:surfconext), do: {:ok, "/auth/surfconext"}, else: :unavailable
  end

  defp provider_path("centerdata", _login_hint) do
    if Methods.provider?(:centerdata) and feature_enabled?(:centerdata_sign_in),
      do: {:ok, "/auth/centerdata"},
      else: :unavailable
  end

  defp provider_path("mock", login_hint) do
    if Methods.provider?(:mock),
      do: {:ok, with_query("/auth/mock/callback", :email, login_hint)},
      else: :unavailable
  end

  defp provider_path(_provider, _login_hint), do: :error

  defp with_login_hint(path, hint), do: with_query(path, :login_hint, hint)

  defp with_query(path, key, value) when is_binary(value) and value != "",
    do: "#{path}?#{URI.encode_query([{key, value}])}"

  defp with_query(path, _key, _value), do: path

  defp return_to(%{"return_to" => return_to}), do: ReturnTo.sanitize(return_to)
  defp return_to(_params), do: nil
end
