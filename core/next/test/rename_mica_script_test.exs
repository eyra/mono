defmodule Next.RenameMicaScriptTest do
  # scripts/rename_mica.exs (Nova step code-rename) runs on open branches after the
  # rename has merged. A branch that merged the script commit (518b41719) has the
  # stored-names migration under its first version, 20261030120000; the script must
  # leave it alone under every version, or the migration renames nothing.
  # Not async: one test sets GIT_DIR in the environment, as a git hook does.
  use ExUnit.Case, async: false

  @moduletag :tmp_dir

  @script Path.expand("../../scripts/rename_mica.exs", __DIR__)
  @migration_dir Path.expand("../../priv/repo/migrations", __DIR__)
  @versions ~w(20261030120000 20261031091717 20261102154500)

  describe "the script on a branch" do
    setup %{tmp_dir: tmp_dir} do
      init_repo(tmp_dir)
      [migration] = Path.wildcard(Path.join(@migration_dir, "*_rename_stored_module_names.exs"))
      source = File.read!(migration)

      for version <- @versions do
        write(
          tmp_dir,
          "core/priv/repo/migrations/#{version}_rename_stored_module_names.exs",
          source
        )
      end

      write(tmp_dir, "core/mica/lib/core/example.ex", "defmodule Core.Example, do: :core\n")

      # A Next system that, on this branch, only has a folder: no module defines it yet.
      write(tmp_dir, "core/next/systems/widget/README.md", "Widget\n")
      write(tmp_dir, "core/next/lib/uses_widget.ex", "alias Systems.Widget.Model\n")

      {output, 0} =
        System.cmd("elixir", [@script],
          cd: tmp_dir,
          env: without_git_env(),
          stderr_to_stdout: true
        )

      %{source: source, output: output}
    end

    test "renames old names", %{tmp_dir: tmp_dir} do
      assert File.read!(Path.join(tmp_dir, "core/mica/lib/mica/example.ex")) ==
               "defmodule Mica.Example, do: :mica\n"
    end

    test "renames a Next system that only has a folder", %{tmp_dir: tmp_dir} do
      assert File.read!(Path.join(tmp_dir, "core/next/lib/uses_widget.ex")) ==
               "alias Next.Systems.Widget.Model\n"
    end

    for version <- @versions do
      test "leaves the stored-names migration #{version} alone",
           %{tmp_dir: tmp_dir, source: source} do
        path = "core/priv/repo/migrations/#{unquote(version)}_rename_stored_module_names.exs"
        assert File.read!(Path.join(tmp_dir, path)) == source
      end
    end

    test "the stored-names migration renames every name it lists", %{source: source} do
      renames = Regex.scan(~r/\{"([\w.]+)", "([\w.]+)"\}/, source, capture: :all_but_first)

      assert renames != []
      assert Enum.all?(renames, fn [from, to] -> from != to end)
    end
  end

  describe "under a git hook" do
    # A hook in a worktree exports GIT_DIR (.git/worktrees/<name>) and GIT_INDEX_FILE.
    # Here they point at a throwaway repository and worktree in the test's directory,
    # never the real one.
    test "the test's repository setup leaves the hook's repository alone", %{tmp_dir: tmp_dir} do
      hook_repo = Path.join(tmp_dir, "hook_repo")
      work = Path.join(tmp_dir, "work")
      File.mkdir_p!(work)
      git = &System.cmd("git", &1, cd: hook_repo, env: without_git_env(), stderr_to_stdout: true)
      {_, 0} = System.cmd("git", ["init", "--quiet", hook_repo], env: without_git_env())
      {_, 0} = git.(~w(-c user.name=t -c user.email=t@t commit --quiet --allow-empty -m t))
      {_, 0} = git.(~w(worktree add --quiet --detach ../hook_worktree))
      git_dir = Path.join([hook_repo, ".git", "worktrees", "hook_worktree"])

      with_env(%{"GIT_DIR" => git_dir, "GIT_INDEX_FILE" => Path.join(git_dir, "index")}, fn ->
        init_repo(work)
      end)

      assert {"false\n", 0} =
               System.cmd("git", ["config", "--get", "core.bare"],
                 cd: hook_repo,
                 env: without_git_env()
               )

      assert File.dir?(Path.join(work, ".git"))
    end
  end

  defp init_repo(dir),
    do: {_, 0} = System.cmd("git", ["init", "--quiet"], cd: dir, env: without_git_env())

  # The pre-push hook runs this suite with GIT_DIR and GIT_INDEX_FILE set to the real
  # repository. Inherited, they make `git init` reinitialise that repository (setting
  # core.bare = true in the config all worktrees share) and the script read its index.
  defp without_git_env, do: for({"GIT_" <> _ = name, _} <- System.get_env(), do: {name, nil})

  defp with_env(vars, fun) do
    saved = Map.new(vars, fn {name, _} -> {name, System.get_env(name)} end)
    System.put_env(vars)

    try do
      fun.()
    after
      Enum.each(saved, fn
        {name, nil} -> System.delete_env(name)
        {name, value} -> System.put_env(name, value)
      end)
    end
  end

  defp write(dir, path, content) do
    path = Path.join(dir, path)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, content)
  end
end
