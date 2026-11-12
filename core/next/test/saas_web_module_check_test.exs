defmodule Next.SaasWebModuleCheckTest do
  use Credo.Test.Case

  @core Path.expand("../..", __DIR__)

  unless Code.ensure_loaded?(BoundaryRules),
    do: Code.require_file("scripts/boundary_rules.ex", @core)

  unless Code.ensure_loaded?(Credo.Check.Warning.SaasWebModule),
    do: Code.require_file("custom_credo_checks/saas_web_module.ex", @core)

  alias Credo.Check.Warning.SaasWebModule

  # The test suite doesn't start credo, which parses sources in its own processes.
  setup_all do
    {:ok, _} = Application.ensure_all_started(:credo)
    :ok
  end

  @source """
  defmodule Example do
    use MicaWeb, :routed_live_view
    use MicaWeb.LiveForm
  end
  """

  test "reports use MicaWeb in Next's code" do
    @source
    |> to_source_file("next/systems/widget/page.ex")
    |> run_check(SaasWebModule)
    |> assert_issue(fn issue ->
      assert issue.line_no == 2
      assert issue.message =~ "Use NextWeb"
    end)
  end

  test "reports use MicaWeb in Self's code, tests included" do
    @source
    |> to_source_file("mica_saas/test/widget_test.exs")
    |> run_check(SaasWebModule)
    |> assert_issue(fn issue -> assert issue.message =~ "Use MicaSaasWeb" end)
  end

  test "allows the SaaS's own web module and Mica's other modules" do
    """
    defmodule Example do
      use NextWeb, {:controller, [formats: [:json]]}
      use MicaWeb.LiveForm
      use MicaWeb.Web, router: MicaWeb.Router, endpoint: MicaWeb.Endpoint
    end
    """
    |> to_source_file("next/systems/widget/controller.ex")
    |> run_check(SaasWebModule)
    |> refute_issues()
  end

  test "allows use MicaWeb in Mica" do
    @source
    |> to_source_file("mica/systems/widget/page.ex")
    |> run_check(SaasWebModule)
    |> refute_issues()
  end

  describe "~p in Mica" do
    test "reports ~p in Mica's code, HEEx templates included" do
      ~S'''
      defmodule Systems.Widget.Page do
        use MicaWeb, :routed_live_view

        def path(widget), do: ~p"/widget/#{widget}"

        def render(assigns) do
          ~H"""
          <img src={~p"/images/widget.svg"} />
          """
        end
      end
      '''
      |> to_source_file("mica/systems/widget/page.ex")
      |> run_check(SaasWebModule)
      |> assert_issues(fn issues ->
        assert issues |> Enum.map(& &1.line_no) |> Enum.sort() == [4, 8]
        assert Enum.all?(issues, &(&1.message =~ "Use ~m (MicaWeb.Path)"))
      end)
    end

    test "reports ~p in Mica's tests" do
      ~S'''
      defmodule Systems.Widget.PageTest do
        test "opens", %{conn: conn}, do: live(conn, ~p"/widget")
      end
      '''
      |> to_source_file("mica/test/systems/widget/page_test.exs")
      |> run_check(SaasWebModule)
      |> assert_issue(fn issue -> assert issue.line_no == 2 end)
    end

    test "allows ~m, and ~p named in docs" do
      ~S'''
      defmodule Systems.Widget.Page do
        @moduledoc "Builds paths with `~m`, never `~p`."
        def path(widget), do: ~m"/widget/#{widget}"
      end
      '''
      |> to_source_file("mica/systems/widget/page.ex")
      |> run_check(SaasWebModule)
      |> refute_issues()
    end

    test "allows ~p in SaaS code" do
      ~S'''
      defmodule Next.Systems.Widget.Page do
        use NextWeb, :routed_live_view
        def path(widget), do: ~p"/widget/#{widget}"
      end
      '''
      |> to_source_file("next/systems/widget/page.ex")
      |> run_check(SaasWebModule)
      |> refute_issues()
    end
  end
end
