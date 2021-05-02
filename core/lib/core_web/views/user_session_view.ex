defmodule CoreWeb.UserSessionView do
  use CoreWeb, :view

  def sign_in_with_apple_button(conn) do
    config = Application.fetch_env!(:core, SignInWithApple)
    {:safe, SignInWithApple.Helpers.html_sign_in_button(conn, config)}
  end
end
