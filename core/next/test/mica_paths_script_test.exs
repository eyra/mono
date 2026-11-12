defmodule Next.MicaPathsScriptTest do
  # scripts/mica_paths.exs (code-compose PR 6) runs on open branches after the
  # swap has merged, so it must be idempotent and leave SaaS code alone.
  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  @script Path.expand("../../scripts/mica_paths.exs", __DIR__)

  setup %{tmp_dir: tmp_dir} do
    {_, 0} = System.cmd("git", ["init", "--quiet"], cd: tmp_dir, env: without_git_env())

    write(tmp_dir, "core/mica/systems/widget/page.ex", ~S'''
    defmodule Systems.Widget.Page do
      use MicaWeb, :routed_live_view

      def path(widget), do: ~p"/widget/#{widget}?#{[tab: "x"]}"

      def render(assigns) do
        ~H"""
        <img src={~p"/images/icons/#{"#{@icon}.svg"}"} />
        """
      end
    end
    ''')

    write(tmp_dir, "core/mica/systems/widget/page.html.heex", ~S'''
    <.link href={~p"/widget"}>Widgets</.link>
    ''')

    write(tmp_dir, "core/mica/test/systems/widget/page_test.exs", ~S'''
    defmodule Systems.Widget.PageTest do
      test "opens", %{conn: conn}, do: live(conn, ~p"/widget")
    end
    ''')

    write(tmp_dir, "core/next/systems/gadget/page.ex", ~S'''
    defmodule Next.Systems.Gadget.Page do
      use NextWeb, :routed_live_view
      def path, do: ~p"/gadget"
    end
    ''')

    :ok
  end

  test "switches Mica's ~p to ~m, tests and templates included", %{tmp_dir: tmp_dir} do
    assert {"mica_paths: rewrote 4 ~p in 3 files\n", 0} = run(tmp_dir)

    page = read(tmp_dir, "core/mica/systems/widget/page.ex")
    assert page =~ ~S|def path(widget), do: ~m"/widget/#{widget}?#{[tab: "x"]}"|
    assert page =~ ~S|<img src={~m"/images/icons/#{"#{@icon}.svg"}"} />|
    assert read(tmp_dir, "core/mica/systems/widget/page.html.heex") =~ ~S|href={~m"/widget"}|

    assert read(tmp_dir, "core/mica/test/systems/widget/page_test.exs") =~
             ~S|live(conn, ~m"/widget")|

    assert read(tmp_dir, "core/next/systems/gadget/page.ex") =~ ~S|def path, do: ~p"/gadget"|
  end

  test "is idempotent", %{tmp_dir: tmp_dir} do
    {_, 0} = run(tmp_dir)
    rewritten = read(tmp_dir, "core/mica/systems/widget/page.ex")

    assert {"mica_paths: nothing left to rewrite\n", 0} = run(tmp_dir)
    assert read(tmp_dir, "core/mica/systems/widget/page.ex") == rewritten
  end

  test "--check lists the Mica files still on ~p and changes nothing", %{tmp_dir: tmp_dir} do
    assert {output, 1} = run(tmp_dir, ["--check"])
    assert output =~ "2 ~p in core/mica/systems/widget/page.ex"
    assert output =~ "1 ~p in core/mica/test/systems/widget/page_test.exs"
    refute output =~ "core/next/"
    assert read(tmp_dir, "core/mica/systems/widget/page.ex") =~ ~S|~p"/widget/|

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
