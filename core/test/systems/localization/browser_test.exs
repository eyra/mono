defmodule Systems.Localization.BrowserTest do
  use ExUnit.Case, async: true

  alias Systems.Localization.Resolvers.BrowserDetection

  test "prefers the locale with the highest quality value" do
    locale =
      BrowserDetection.detect_locale("de;q=0.4,nl;q=0.9,en;q=0.8",
        supported_locales: ["en", "nl", "de"]
      )

    assert locale == "nl"
  end

  test "falls back to default when nothing matches" do
    assert BrowserDetection.detect_locale("jp,ko", supported_locales: ["en", "nl"]) == "en"
  end

  test "returns default when no header is provided" do
    assert BrowserDetection.detect_locale(nil, supported_locales: ["en", "nl"]) == "en"
  end

  test "respects the supported_locales whitelist" do
    assert BrowserDetection.detect_locale("nl", supported_locales: ["en"]) == "en"
  end
end
