# Nova migration step code-compose, PR 6 (docs/nova-migration/plan.md).
#
# Mica has no router, so its code builds its paths with `~m` (`MicaWeb.Path`),
# which every SaaS checks against its own router: `~p"` becomes `~m"` in every
# source file under core/mica/, tests included. SaaS code keeps `~p`.
#
# Idempotent: it only rewrites `~p"` that is still there, so it can be re-run on
# any branch, and on a merge that brings it back.
#
# Usage, from anywhere in the repository:
#   elixir core/scripts/mica_paths.exs            # rewrite
#   elixir core/scripts/mica_paths.exs --check    # list files still on ~p, exit 1 if any

defmodule MicaPaths do
  @source_exts ~w(.ex .exs .heex .eex)
  @folder "core/mica/"
  @sigil_p ~r/~p"/

  def main(args) do
    File.cd!(root())
    check? = "--check" in args

    pending =
      for file <- source_files(@folder),
          source = File.read!(file),
          count = length(Regex.scan(@sigil_p, source)),
          count > 0,
          do: {file, count, source}

    cond do
      check? and pending != [] ->
        Enum.each(pending, fn {file, count, _} -> IO.puts("#{count} ~p in #{file}") end)
        System.halt(1)

      pending == [] ->
        IO.puts("mica_paths: nothing left to rewrite")

      true ->
        for {file, _, source} <- pending do
          File.write!(file, String.replace(source, ~s(~p"), ~s(~m")))
        end

        uses = pending |> Enum.map(&elem(&1, 1)) |> Enum.sum()
        IO.puts("mica_paths: rewrote #{uses} ~p in #{length(pending)} files")
    end
  end

  defp source_files(folder) do
    {out, 0} =
      System.cmd("git", ~w(ls-files -z --cached --others --exclude-standard --) ++ [folder])

    out
    |> String.split(<<0>>, trim: true)
    |> Enum.filter(&(Path.extname(&1) in @source_exts and File.regular?(&1)))
  end

  defp root do
    {out, 0} = System.cmd("git", ~w(rev-parse --show-toplevel))
    String.trim(out)
  end
end

MicaPaths.main(System.argv())
