defmodule Next.MicaTestNeedsNoSaasCheckTest do
  use Credo.Test.Case

  @core Path.expand("../..", __DIR__)

  unless Code.ensure_loaded?(BoundaryRules),
    do: Code.require_file("scripts/boundary_rules.ex", @core)

  unless Code.ensure_loaded?(Credo.Check.Warning.MicaTestNeedsNoSaas),
    do: Code.require_file("custom_credo_checks/mica_test_needs_no_saas.ex", @core)

  alias Credo.Check.Warning.MicaTestNeedsNoSaas

  # The test suite doesn't start credo, which parses sources in its own processes.
  setup_all do
    {:ok, _} = Application.ensure_all_started(:credo)
    :ok
  end

  @conn_test """
  defmodule Systems.Widget.PageTest do
    use MicaWeb.ConnCase, async: true
    import Phoenix.ConnTest
    @endpoint NextWeb.Endpoint

    test "opens", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~m"/widget")
      {:ok, _view, _html} = live_isolated(conn, Widget.View, session: %{})
      Phoenix.LiveViewTest.follow_redirect(render_click(view, "go"), conn)
    end
  end
  """

  test "reports router and endpoint tests in Mica's tests" do
    triggers =
      @conn_test
      |> to_source_file("mica/test/systems/widget/page_test.exs")
      |> run_check(MicaTestNeedsNoSaas)
      |> assert_issues()
      |> Enum.map(&{&1.line_no, &1.trigger})
      |> Enum.sort()

    assert triggers == [
             {2, "MicaWeb.ConnCase"},
             {3, "Phoenix.ConnTest"},
             {4, "@endpoint"},
             {7, "live"},
             {8, "live_isolated"},
             {9, "Phoenix.LiveViewTest.follow_redirect"}
           ]
  end

  test "reports feature tests and the SaaS's case modules" do
    """
    defmodule MicaWeb.Features.WidgetTest do
      use MicaWeb.FeatureCase
      import Wallaby.Query
      alias MicaSaasWeb.ChannelCase
    end
    """
    |> to_source_file("mica/test/features/widget_test.exs")
    |> run_check(MicaTestNeedsNoSaas)
    |> assert_issues(fn issues ->
      assert Enum.map(issues, & &1.trigger) |> Enum.sort() ==
               ["MicaSaasWeb.ChannelCase", "MicaWeb.FeatureCase", "Wallaby"]
    end)
  end

  test "reports Mica's test support too" do
    """
    defmodule Mica.AuthTestHelpers do
      def login(conn), do: Phoenix.ConnTest.init_test_session(conn, %{})
    end
    """
    |> to_source_file("mica/test/support/helpers.ex")
    |> run_check(MicaTestNeedsNoSaas)
    |> assert_issue(fn issue -> assert issue.message =~ "core/mica_saas/test" end)
  end

  test "allows component, data and plain tests" do
    """
    defmodule Systems.Widget.CardTest do
      use Mica.DataCase
      import Phoenix.LiveViewTest
      # live(conn, ~m"/widget") would need an endpoint
      @endpoint %{"account_name" => "acc", "container" => "box"}

      test "renders", %{live: live} do
        html = render_component(&Widget.Html.card/1, live: live)
        assert html =~ "Widget"
        assert Widget.url(@endpoint, "a.json")
      end
    end
    """
    |> to_source_file("mica/test/systems/widget/card_test.exs")
    |> run_check(MicaTestNeedsNoSaas)
    |> refute_issues()
  end

  test "allows router and endpoint tests in the SaaS suites" do
    for path <- ["mica_saas/test/systems/widget/page_test.exs", "next/test/widget_test.exs"] do
      @conn_test
      |> to_source_file(path)
      |> run_check(MicaTestNeedsNoSaas)
      |> refute_issues()
    end
  end
end
