defmodule SignInWithApple.Helpers.Test do
  use ExUnit.Case, async: true

  alias SignInWithApple.Helpers

  test "backend_module/1 returns the backend override" do
    assert Helpers.backend_module(apple_backend_module: :test) == :test
  end

  test "apply_defaults/1 merges the Apple required defaults" do
    assert Helpers.apply_defaults([]) |> Keyword.get(:site) == "https://appleid.apple.com"
  end

  test "html_meta/1 returns the meta tags that are needed" do
    html = Helpers.html_meta(redirect_uri: Faker.Internet.url(), client_id: "testing")
    assert html =~ "<meta name=\"appleid-signin-client-id\" content=\"testing\""
  end

  test "html_sign_in_button/1 returns the html for the button" do
    html = Helpers.html_sign_in_button()
    assert html =~ "cdn-apple.com"
  end
end
