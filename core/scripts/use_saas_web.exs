# Nova migration step code-compose, PR 5 (docs/nova-migration/plan.md).
#
# SaaS code uses its own web module, so its `~p` is verified against that SaaS's
# router: `use MicaWeb, …` becomes `use NextWeb, …` under core/next/ and
# `use MicaSaasWeb, …` under core/mica_saas/. Mica's other modules
# (`use MicaWeb.LiveForm`, `use MicaWeb.ConnCase`, …) are left alone.
#
# Idempotent: it only rewrites `use MicaWeb` that is still there, so it can be
# re-run on any branch, and on a merge that brings it back.
#
# Usage, from anywhere in the repository:
#   elixir core/scripts/use_saas_web.exs            # rewrite
#   elixir core/scripts/use_saas_web.exs --check    # list files still on MicaWeb, exit 1 if any

defmodule UseSaasWeb do
  @source_exts ~w(.ex .exs .heex .eex)
  @web_modules %{"core/next/" => "NextWeb", "core/mica_saas/" => "MicaSaasWeb"}
  # Its own test and the credo check's test name `use MicaWeb` on purpose.
  @excluded ~r"(use_saas_web_script_test|saas_web_module_check_test)\.exs$"
  @use_mica_web ~r/\buse MicaWeb(?![\w.])/

  def main(args) do
    File.cd!(root())
    check? = "--check" in args

    pending =
      for {folder, web} <- @web_modules,
          file <- source_files(folder),
          source = File.read!(file),
          Regex.match?(@use_mica_web, source),
          do: {file, web, source}

    cond do
      check? and pending != [] ->
        Enum.each(pending, fn {file, web, _} ->
          IO.puts("use MicaWeb instead of #{web} in #{file}")
        end)

        System.halt(1)

      pending == [] ->
        IO.puts("use_saas_web: nothing left to rewrite")

      true ->
        for {file, web, source} <- pending do
          File.write!(file, Regex.replace(@use_mica_web, source, "use #{web}"))
        end

        IO.puts("use_saas_web: rewrote #{length(pending)} files")
    end
  end

  defp source_files(folder) do
    {out, 0} =
      System.cmd("git", ~w(ls-files -z --cached --others --exclude-standard --) ++ [folder])

    out
    |> String.split(<<0>>, trim: true)
    |> Enum.filter(&(Path.extname(&1) in @source_exts and File.regular?(&1)))
    |> Enum.reject(&Regex.match?(@excluded, &1))
  end

  defp root do
    {out, 0} = System.cmd("git", ~w(rev-parse --show-toplevel))
    String.trim(out)
  end
end

UseSaasWeb.main(System.argv())
