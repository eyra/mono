defmodule MicaSaasWeb.PathCheckTest do
  # Every SaaS checks every Mica path (`~m`) against its own router.
  use ExUnit.Case, async: true

  alias MicaWeb.PathCheck

  test "every Mica path matches a route of Self's router that Mica serves" do
    issues = PathCheck.unmatched(MicaSaasWeb.Router)
    assert issues == [], PathCheck.format(issues, MicaSaasWeb.Router)
  end

  test "Self's sign-in pages are recorded as its override routes" do
    overrides = MicaSaasWeb.Router.__mica_override_routes__()
    assert "/user/signin" in overrides
    assert "/user/auth/identify" in overrides
    refute "/user/auth/:provider" in overrides
  end
end
