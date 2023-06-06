defmodule Link.User.SessionHTML do
  use CoreWeb, :html

  import CoreWeb.UI.Footer
  import CoreWeb.UI.Language

  embed_templates("session_html/*")

  def sign_in_with_apple_button(conn) do
    config = Application.fetch_env!(:core, SignInWithApple)
    {:safe, SignInWithApple.Helpers.html_sign_in_button(conn, config)}
  end
end
