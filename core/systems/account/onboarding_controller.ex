defmodule Systems.Account.OnboardingController do
  @moduledoc """
  Controller to handle onboarding entry for Panl participants.

  After signup, participants are redirected here with a signed token
  to be auto-logged in and sent to the onboarding page.
  """
  use CoreWeb,
      {:controller, [formats: [:html], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]}

  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Account

  @token_salt "onboarding_token"
  @token_max_age 300

  def start(conn, %{"token" => token, "locale" => locale}) do
    case verify_token(token) do
      {:ok, user_id} ->
        user = Account.Public.get_user!(user_id)

        conn
        |> Account.UserAuth.log_in_user_for_onboarding(user, locale)
        |> redirect(to: ~p"/user/onboarding")

      {:error, _reason} ->
        conn
        |> put_flash(:error, dgettext("eyra-account", "onboarding.token.invalid"))
        |> redirect(to: ~p"/user/signin")
    end
  end

  defp verify_token(token) do
    Phoenix.Token.verify(CoreWeb.Endpoint, @token_salt, token, max_age: @token_max_age)
  end

  def generate_token(user) do
    Phoenix.Token.sign(CoreWeb.Endpoint, @token_salt, user.id)
  end
end
