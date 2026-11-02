defmodule Next.RenameMicaScriptTest do
  # scripts/rename_mica.exs (Nova step code-rename) runs on open branches after the
  # rename has merged. A branch that merged the script commit (518b41719) has the
  # stored-names migration under its first version, 20261030120000; the script must
  # leave it alone under every version, or the migration renames nothing.
  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  @script Path.expand("../../scripts/rename_mica.exs", __DIR__)
  @migration_dir Path.expand("../../priv/repo/migrations", __DIR__)
  @versions ~w(20261030120000 20261031091717)

  setup %{tmp_dir: tmp_dir} do
    {_, 0} = System.cmd("git", ["init", "--quiet"], cd: tmp_dir)
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

    {output, 0} = System.cmd("elixir", [@script], cd: tmp_dir, stderr_to_stdout: true)
    %{source: source, output: output}
  end

  test "the script renames old names", %{tmp_dir: tmp_dir} do
    assert File.read!(Path.join(tmp_dir, "core/mica/lib/mica/example.ex")) ==
             "defmodule Mica.Example, do: :mica\n"
  end

  for version <- @versions do
    test "the script leaves the stored-names migration #{version} alone",
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

  defp write(dir, path, content) do
    path = Path.join(dir, path)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, content)
  end
end
