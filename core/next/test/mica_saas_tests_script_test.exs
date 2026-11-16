defmodule Next.MicaSaasTestsScriptTest do
  # scripts/mica_saas_tests.exs (code-compose PR 9) runs on open branches after the
  # move has merged, so it must be idempotent, keep each file's history and leave
  # Mica's other tests alone.
  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  @script Path.expand("../../scripts/mica_saas_tests.exs", __DIR__)

  setup %{tmp_dir: tmp_dir} do
    git!(tmp_dir, ["init", "--quiet"])

    write(tmp_dir, "core/mica/test/systems/widget/page_test.exs", ~S'''
    defmodule Systems.Widget.PageTest.View do
      use MicaWeb, :live_view_fabric
      use MicaWeb.LiveForm
    end

    defmodule Systems.Widget.PageTest do
      use MicaWeb.ConnCase, async: true

      test "opens", %{conn: conn}, do: live_isolated(conn, Systems.Widget.PageTest.View)
    end
    ''')

    write(tmp_dir, "core/mica/test/mica_web/widget_controller_test.exs", ~S'''
    defmodule Systems.Widget.FakeClient do
      def fetch, do: :ok
    end

    defmodule MicaWeb.WidgetControllerTest do
      use MicaWeb.ConnCase

      setup do
        Application.put_env(:mica, :widget_client, Systems.Widget.FakeClient)
        Mox.defmock(Systems.Widget.FakeClient.Mock, for: Widget)
      end

      test "shows", %{conn: conn}, do: get(conn, "/widget")
      test "fetches", do: assert(Systems.Widget.FakeClient.fetch() == :ok)
    end
    ''')

    write(tmp_dir, "core/mica/test/systems/pool/panl_signup_test.exs", ~S'''
    defmodule Systems.Pool.PanlSignupTest do
      use MicaWeb.ConnCase
    end
    ''')

    write(tmp_dir, "core/mica/test/features/widget_test.exs", ~S'''
    defmodule MicaWeb.Features.WidgetTest do
      use MicaWeb.FeatureCase
    end
    ''')

    write(tmp_dir, "core/mica/test/systems/widget/model_test.exs", ~S'''
    defmodule Systems.Widget.ModelTest do
      @moduledoc "Not a Wallaby feature test."
      use Mica.DataCase
      # live(conn, ~m"/widget") would need an endpoint
    end
    ''')

    write(tmp_dir, "core/mica/test/support/conn_case.ex", ~S'''
    defmodule MicaWeb.ConnCase do
      use ExUnit.CaseTemplate
      import MicaWeb.ConnCase
    end
    ''')

    write(tmp_dir, "core/next/test/systems/gadget/page_test.exs", ~S'''
    defmodule Next.Systems.Gadget.PageTest do
      use MicaWeb.ConnCase
      use NextWeb, :verified_routes
      def conn, do: MicaWeb.ConnCase.build_conn()
    end
    ''')

    git!(tmp_dir, ["add", "."])
    git!(tmp_dir, ~w(-c user.email=test@example.org -c user.name=Test commit --quiet -m fixtures))
    :ok
  end

  test "moves the router and endpoint tests to the SaaS suites", %{tmp_dir: tmp_dir} do
    assert {"mica_saas_tests: moved 5 files (1 to core/next/test), rewrote 6 files\n", 0} =
             run(tmp_dir)

    assert read(tmp_dir, "core/mica_saas/test/systems/widget/page_test.exs") == ~S'''
           defmodule MicaSaas.Systems.Widget.PageTest.View do
             use MicaSaasWeb, :live_view_fabric
             use MicaWeb.LiveForm
           end

           defmodule MicaSaas.Systems.Widget.PageTest do
             use MicaSaasWeb.ConnCase, async: true

             test "opens", %{conn: conn}, do: live_isolated(conn, MicaSaas.Systems.Widget.PageTest.View)
           end
           '''

    assert read(tmp_dir, "core/mica_saas/test/features/widget_test.exs") =~
             "defmodule MicaSaasWeb.Features.WidgetTest do\n  use MicaSaasWeb.FeatureCase"

    assert read(tmp_dir, "core/next/test/systems/pool/panl_signup_test.exs") =~
             "defmodule Next.Systems.Pool.PanlSignupTest do\n  use NextWeb.ConnCase"

    assert read(tmp_dir, "core/mica_saas/test/support/conn_case.ex") =~
             "defmodule MicaSaasWeb.ConnCase do\n  use ExUnit.CaseTemplate\n  import MicaSaasWeb.ConnCase"

    refute File.exists?(Path.join(tmp_dir, "core/mica/test/systems/widget/page_test.exs"))

    assert read(tmp_dir, "core/mica/test/systems/widget/model_test.exs") =~
             "Systems.Widget.ModelTest"
  end

  test "renames a top-level module with every use of its exact name", %{tmp_dir: tmp_dir} do
    {_, 0} = run(tmp_dir)
    controller = read(tmp_dir, "core/mica_saas/test/mica_web/widget_controller_test.exs")

    assert controller =~ "defmodule MicaSaas.Systems.Widget.FakeClient do"
    assert controller =~ "defmodule MicaSaasWeb.WidgetControllerTest do"
    assert controller =~ "put_env(:mica, :widget_client, MicaSaas.Systems.Widget.FakeClient)"
    assert controller =~ "assert(MicaSaas.Systems.Widget.FakeClient.fetch() == :ok)"
    assert controller =~ "Mox.defmock(Systems.Widget.FakeClient.Mock, for: Widget)"
  end

  test "points the SaaS's own tests at its own case modules", %{tmp_dir: tmp_dir} do
    {_, 0} = run(tmp_dir)

    assert read(tmp_dir, "core/next/test/systems/gadget/page_test.exs") == ~S'''
           defmodule Next.Systems.Gadget.PageTest do
             use NextWeb.ConnCase
             use NextWeb, :verified_routes
             def conn, do: NextWeb.ConnCase.build_conn()
           end
           '''
  end

  test "--move only moves, so git keeps each file's history", %{tmp_dir: tmp_dir} do
    assert {"mica_saas_tests: moved 5 files (1 to core/next/test), rewrote 0 files\n", 0} =
             run(tmp_dir, ["--move"])

    {status, 0} =
      System.cmd("git", ~w(diff --cached --name-status -M),
        cd: tmp_dir,
        env: without_git_env()
      )

    renames = for "R100\t" <> paths <- String.split(status, "\n", trim: true), do: paths
    assert length(renames) == 5

    assert "core/mica/test/systems/widget/page_test.exs\tcore/mica_saas/test/systems/widget/page_test.exs" in renames

    assert read(tmp_dir, "core/next/test/systems/gadget/page_test.exs") =~ "use MicaWeb.ConnCase"
  end

  test "is idempotent", %{tmp_dir: tmp_dir} do
    {_, 0} = run(tmp_dir)
    moved = read(tmp_dir, "core/mica_saas/test/mica_web/widget_controller_test.exs")

    assert {"mica_saas_tests: nothing left to move or rewrite\n", 0} = run(tmp_dir)
    assert read(tmp_dir, "core/mica_saas/test/mica_web/widget_controller_test.exs") == moved
  end

  test "--check lists what is left and changes nothing", %{tmp_dir: tmp_dir} do
    assert {output, 1} = run(tmp_dir, ["--check"])

    assert output =~
             "move core/mica/test/systems/widget/page_test.exs to core/mica_saas/test/systems/widget/page_test.exs"

    assert output =~ "rewrite core/next/test/systems/gadget/page_test.exs"
    refute output =~ "model_test.exs"
    assert File.exists?(Path.join(tmp_dir, "core/mica/test/systems/widget/page_test.exs"))

    {_, 0} = run(tmp_dir)
    assert {"mica_saas_tests: nothing left to move or rewrite\n", 0} = run(tmp_dir, ["--check"])
  end

  defp run(dir, args \\ []) do
    System.cmd("elixir", [@script | args],
      cd: dir,
      env: without_git_env(),
      stderr_to_stdout: true
    )
  end

  defp git!(dir, args) do
    {_, 0} = System.cmd("git", args, cd: dir, env: without_git_env(), stderr_to_stdout: true)
  end

  # Under a git hook, GIT_DIR and GIT_INDEX_FILE point at the real repository.
  defp without_git_env, do: for({"GIT_" <> _ = name, _} <- System.get_env(), do: {name, nil})

  defp read(dir, path), do: File.read!(Path.join(dir, path))

  defp write(dir, path, content) do
    path = Path.join(dir, path)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, content)
  end
end
