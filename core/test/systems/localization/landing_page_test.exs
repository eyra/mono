defmodule Systems.Localization.LandingPageTest do
  use ExUnit.Case, async: true

  alias Systems.Localization.Resolvers.LandingPage

  test "uses browser detection for guests" do
    locale =
      LandingPage.resolve_locale(
        logged_in?: false,
        panl_participant?: false,
        accept_language: "nl,en"
      )

    assert locale == "nl"
  end

  test "uses browser detection for logged in panl participants" do
    locale =
      LandingPage.resolve_locale(
        logged_in?: true,
        panl_participant?: true,
        accept_language: "nl,en"
      )

    assert locale == "nl"
  end

  test "forces default locale for logged in non-panl users" do
    locale =
      LandingPage.resolve_locale(
        logged_in?: true,
        panl_participant?: false,
        accept_language: "nl,en",
        default_locale: "en"
      )

    assert locale == "en"
  end

  test "defaults when the header is missing" do
    locale =
      LandingPage.resolve_locale(
        logged_in?: false,
        panl_participant?: false,
        accept_language: nil,
        default_locale: "en"
      )

    assert locale == "en"
  end
end
