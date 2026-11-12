defmodule NextWeb.PathCheckTest do
  # Next checks every Mica path (`~m`) against its router (code-compose PR 6).
  # The router is still Mica's until PR 8 gives Next its own.
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias MicaWeb.PathCheck

  test "every Mica path matches a route of Next's router that Mica serves" do
    issues = PathCheck.unmatched(MicaWeb.Router)
    assert issues == [], PathCheck.format(issues, MicaWeb.Router)
  end

  test "Next's sign-in pages are recorded as its override routes" do
    overrides = MicaWeb.Router.__mica_override_routes__()
    assert "/user/signin" in overrides
    assert "/user/auth/:provider" in overrides
    refute "/assignment/:id" in overrides
  end

  defmodule Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require MicaWeb.PathCheck

    get("/mica/page", MicaWeb.HealthController, :get)
    live("/mica/live/:id", Systems.Assignment.CrewPage)
    get("/saas/page", Next.Systems.Account.SessionController, :new)
    live("/saas/live", Next.Systems.Account.SigninPage)

    MicaWeb.PathCheck.overrides do
      scope "/saas", Next.Systems do
        live("/override/:id", Account.SigninPage)
      end
    end

    post("/mica/form", MicaWeb.HealthController, :get)
    post("/saas/page", MicaWeb.HealthController, :get)
  end

  defmodule Links do
    use MicaWeb.Path

    def mica_page, do: ~m"/mica/page"
    def mica_live(id), do: ~m"/mica/live/#{id}?#{[tab: "x"]}"
    def mica_form, do: ~m"/mica/form"
    def misspelled_line, do: __ENV__.line + 1
    def misspelled, do: ~m"/mica/pgae"
    def saas_page, do: ~m"/saas/page"
    def saas_live, do: ~m"/saas/live#top"
    def saas_override(id), do: ~m"/saas/override/#{id}"
  end

  describe "unmatched/2" do
    test "passes paths that match a route Mica serves, whatever the verb" do
      assert [] = PathCheck.unmatched(Router, [Links]) |> Enum.filter(&(&1.path =~ "/mica/live"))

      refute Enum.any?(
               PathCheck.unmatched(Router, [Links]),
               &(&1.path in ["/mica/page", "/mica/form"])
             )
    end

    test "fails a Mica path the router doesn't have" do
      assert [
               %{
                 route: ~S|~m"/mica/pgae"|,
                 reason: :no_route,
                 module: Links,
                 file: file,
                 line: line
               }
             ] =
               PathCheck.unmatched(Router, [Links]) |> Enum.filter(&(&1.reason == :no_route))

      assert file == __ENV__.file
      assert line == Links.misspelled_line()
    end

    test "fails a Mica path that only a SaaS module serves, controller or LiveView" do
      assert [
               %{path: "/saas/live#top", reason: {:served_by, Next.Systems.Account.SigninPage}}
             ] =
               PathCheck.unmatched(Router, [Links]) |> Enum.filter(&(&1.path == "/saas/live#top"))

      # /saas/page also has a POST route that Mica serves, so the GET doesn't fail it.
      refute Enum.any?(PathCheck.unmatched(Router, [Links]), &(&1.path == "/saas/page"))
    end

    test "passes the SaaS's own override routes" do
      assert Router.__mica_override_routes__() == ["/saas/override/:id"]
      refute Enum.any?(PathCheck.unmatched(Router, [Links]), &(&1.path =~ "/saas/override"))
    end
  end

  defmodule SaasOnlyRouter do
    use Phoenix.Router
    get("/saas/page", Next.Systems.Account.SessionController, :new)
  end

  test "a SaaS-only page fails even when no other verb is Mica's" do
    assert [%{reason: {:served_by, Next.Systems.Account.SessionController}}] =
             PathCheck.unmatched(SaasOnlyRouter, [Links])
             |> Enum.filter(&(&1.path == "/saas/page"))
  end

  test "the compile-time warning names the path, its file and line" do
    issues = PathCheck.unmatched(Router, [Links])

    output = capture_io(:stderr, fn -> PathCheck.warn(issues, Router) end)

    assert output =~ ~s|Mica path ~m"/mica/pgae" matches no route in NextWeb.PathCheckTest.Router|

    assert output =~
             ~s|Mica path ~m"/saas/live#top" is served by Next.Systems.Account.SigninPage, not by Mica|

    assert output =~ "next/test/next_web/path_check_test.exs:#{Links.misspelled_line()}"
  end

  test "the test failure lists each path with file and line" do
    text = Router |> PathCheck.unmatched([Links]) |> PathCheck.format(Router)

    assert text =~
             "Mica path ~m\"/mica/pgae\" matches no route in NextWeb.PathCheckTest.Router\n" <>
               "  next/test/next_web/path_check_test.exs:#{Links.misspelled_line()}: NextWeb.PathCheckTest.Links"
  end

  test "override routes are read from scopes, nested and with options" do
    block =
      quote do
        pipeline :native do
          plug(:accepts, ["json"])
        end

        scope "/", Next.Systems do
          pipe_through([:browser])
          live("/user/signin", Account.SigninPage)
          get("/user/session", Account.SessionController, :new)

          scope "/user/auth", as: :auth do
            post("/native/identify", Account.NativeSigninController, :identify)
          end
        end

        scope path: "/nested/" do
          live_session :default do
            live("/page", Account.SigninPage)
          end

          match(:*, "/any", Account.SessionController, :new)
        end

        get("/user/session", Account.SessionController, :new)
      end

    assert PathCheck.route_patterns(block) == [
             "/user/signin",
             "/user/session",
             "/user/auth/native/identify",
             "/nested/page",
             "/nested/any"
           ]
  end
end
