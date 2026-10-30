defmodule MicaWeb.ReturnToTest do
  use ExUnit.Case, async: true

  alias MicaWeb.ReturnTo

  describe "sanitize/1" do
    test "keeps same-site paths" do
      for path <- ["/", "/assignment/1", "/pool/panl/join?x=1", "/a/b\\c", "/user/onboarding#top"] do
        assert ReturnTo.sanitize(path) == path
      end
    end

    test "accepts only same-site paths" do
      for value <- [
            "https://example.org/x",
            "example.org",
            "//example.org/x",
            "/\\example.org",
            "/\t/example.org",
            "/a\nb",
            "",
            nil,
            42
          ] do
        assert ReturnTo.sanitize(value) == nil, "expected #{inspect(value)} to be dropped"
      end
    end
  end
end
