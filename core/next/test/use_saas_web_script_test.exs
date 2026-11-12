defmodule Next.UseSaasWebScriptTest do
  # scripts/use_saas_web.exs (code-compose PR 5) runs on open branches after the
  # swap has merged, so it must be idempotent and leave Mica's code alone.
  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  @script Path.expand("../../scripts/use_saas_web.exs", __DIR__)

  setup %{tmp_dir: tmp_dir} do
    {_, 0} = System.cmd("git", ["init", "--quiet"], cd: tmp_dir, env: without_git_env())

    write(tmp_dir, "core/next/systems/widget/page.ex", """
    defmodule Next.Systems.Widget.Page do
      use MicaWeb, :routed_live_view
      use MicaWeb.LiveForm
    end
    """)

    write(tmp_dir, "core/next/systems/widget/controller.ex", """
    defmodule Next.Systems.Widget.Controller do
      use MicaWeb, {:controller, [formats: [:json]]}
    end
    """)

    write(tmp_dir, "core/mica_saas/lib/menu/items.ex", """
    defmodule MicaSaasWeb.Menu.Items do
      use MicaWeb, :verified_routes
      use MicaWeb.Menu.Builder
    end
    """)

    write(tmp_dir, "core/mica/systems/widget/page.ex", """
    defmodule Systems.Widget.Page do
      use MicaWeb, :routed_live_view
    end
    """)

    :ok
  end

  test "switches SaaS code to its own web module", %{tmp_dir: tmp_dir} do
    assert {"use_saas_web: rewrote 3 files\n", 0} = run(tmp_dir)

    assert read(tmp_dir, "core/next/systems/widget/page.ex") =~
             "use NextWeb, :routed_live_view\n  use MicaWeb.LiveForm\n"

    assert read(tmp_dir, "core/next/systems/widget/controller.ex") =~
             "use NextWeb, {:controller, [formats: [:json]]}"

    assert read(tmp_dir, "core/mica_saas/lib/menu/items.ex") =~
             "use MicaSaasWeb, :verified_routes\n  use MicaWeb.Menu.Builder\n"

    assert read(tmp_dir, "core/mica/systems/widget/page.ex") =~ "use MicaWeb, :routed_live_view"
  end

  test "is idempotent", %{tmp_dir: tmp_dir} do
    {_, 0} = run(tmp_dir)
    rewritten = read(tmp_dir, "core/next/systems/widget/page.ex")

    assert {"use_saas_web: nothing left to rewrite\n", 0} = run(tmp_dir)
    assert read(tmp_dir, "core/next/systems/widget/page.ex") == rewritten
  end

  test "--check lists the files still on MicaWeb and changes nothing", %{tmp_dir: tmp_dir} do
    assert {output, 1} = run(tmp_dir, ["--check"])
    assert output =~ "use MicaWeb instead of NextWeb in core/next/systems/widget/page.ex"
    assert output =~ "use MicaWeb instead of MicaSaasWeb in core/mica_saas/lib/menu/items.ex"
    refute output =~ "core/mica/"
    assert read(tmp_dir, "core/next/systems/widget/page.ex") =~ "use MicaWeb, :routed_live_view"

    {_, 0} = run(tmp_dir)
    assert {_, 0} = run(tmp_dir, ["--check"])
  end

  defp run(dir, args \\ []) do
    System.cmd("elixir", [@script | args],
      cd: dir,
      env: without_git_env(),
      stderr_to_stdout: true
    )
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
