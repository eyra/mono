defmodule LinkWeb.UserSessionView do
  use LinkWeb, :view

  def meta_tags do
    {:safe, SignInWithApple.Helpers.html_meta(Application.fetch_env!(:link, SignInWithApple))}
  end

  def sign_in_with_apple_button do
    {:safe, SignInWithApple.Helpers.html_sign_in_button()}
  end
end
