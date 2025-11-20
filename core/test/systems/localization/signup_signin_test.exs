defmodule Systems.Localization.SignupSigninTest do
  use ExUnit.Case, async: true

  alias Systems.Localization.Resolvers.SignupSignin

  test "uses browser detection by default for signup/signin" do
    locale =
      SignupSignin.resolve_locale(
        accept_language: "nl,en",
        add_to_panl?: false,
        default_locale: "en"
      )

    assert locale == "nl"
  end

  test "forces NL when add_to_panl is active" do
    locale =
      SignupSignin.resolve_locale(
        accept_language: "en",
        add_to_panl?: true,
        default_locale: "en"
      )

    assert locale == "nl"
  end

  test "falls back to default when no header is provided" do
    locale =
      SignupSignin.resolve_locale(
        accept_language: nil,
        add_to_panl?: false,
        default_locale: "en"
      )

    assert locale == "en"
  end
end
