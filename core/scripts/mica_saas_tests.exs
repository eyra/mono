# Nova migration step code-compose, PR 9 (docs/nova-migration/plan.md).
#
# Mica's tests need no SaaS: a test that needs a router or an endpoint is a SaaS
# test. Such tests in core/mica/test (`ConnCase`, `FeatureCase`, `Phoenix.ConnTest`,
# Wallaby, LiveView's `live/2` and `live_isolated/3`) move to Self's suite,
# core/mica_saas/test, and the ones that test Next's behaviour to core/next/test,
# each at the same path below its test folder. `ConnCase`, `FeatureCase` and
# `ChannelCase` move to core/mica_saas/test/support.
#
# Two steps, so that git keeps each file's history:
#   1. move: `git mv`, no content change
#   2. rewrite, in the SaaS test folders: top-level test modules into the SaaS's
#      namespace (`MicaWeb.X` becomes `MicaSaasWeb.X` or `NextWeb.X`, any other
#      `X` becomes `MicaSaas.X` or `Next.X`), the case modules to the SaaS's own
#      (`MicaWeb.ConnCase` becomes `MicaSaasWeb.ConnCase` or `NextWeb.ConnCase`),
#      and `use MicaWeb, …` to the SaaS's web module, as scripts/use_saas_web.exs
#
# Idempotent: it only moves and rewrites what is still left, so it can be re-run
# on any branch, and on a merge that brings a file back.
#
# Usage, from anywhere in the repository:
#   elixir core/scripts/mica_saas_tests.exs           # move and rewrite
#   elixir core/scripts/mica_saas_tests.exs --move    # step 1 only
#   elixir core/scripts/mica_saas_tests.exs --check   # list what is left, exit 1 if any

defmodule MicaSaasTests do
  @mica "core/mica/test/"
  @saases %{
    "core/mica_saas/test/" => %{top: "MicaSaas", web: "MicaSaasWeb"},
    "core/next/test/" => %{top: "Next", web: "NextWeb"}
  }
  @self_dir "core/mica_saas/test/"
  @next_dir "core/next/test/"

  # Tests of Next's behaviour, which go to core/next/test (paths below core/mica/test):
  # they need Next's config (sign-in providers, PaNL pool logos), its citizen pool
  # director, its PaNL sign-up or its code sign-in page.
  @to_next ~w(
    features/auth_identity_provider_transfer_test.exs
    features/terms_and_privacy_onboarding_test.exs
    mica_web/controllers/user_auth_otp_test.exs
    systems/account/auth/identity_provider_transfer_page_test.exs
    systems/advert/content_page_test.exs
    systems/bff/page_controller_test.exs
    systems/pool/panl_signup_test.exs
  )

  @support ~w(support/conn_case.ex support/feature_case.ex support/channel_case.ex)
  @cases ~w(ConnCase FeatureCase ChannelCase)

  # A line of code (not a comment) that needs a router or an endpoint.
  @needs_endpoint ~r/^(?!\s*#).*(MicaWeb\.(ConnCase|FeatureCase|ChannelCase)\b|Phoenix\.ConnTest\b|\bWallaby\.|\blive(_isolated)?\(|@endpoint [A-Z])/m
  @defmodule ~r/^defmodule ([A-Z][\w.]*)/m
  @use_mica_web ~r/\buse MicaWeb(?![\w.])/
  # These tests name the old forms on purpose.
  @excluded ~r"(mica_saas_tests_script_test|mica_test_needs_no_saas_check_test|use_saas_web_script_test|saas_web_module_check_test)\.exs$"

  def main(args) do
    File.cd!(root())
    check? = "--check" in args

    moves = pending_moves()
    rewrites = if "--move" in args, do: [], else: pending_rewrites(moves)

    cond do
      check? and (moves != [] or rewrites != []) ->
        Enum.each(moves, fn {from, to} -> IO.puts("move #{from} to #{to}") end)
        Enum.each(rewrites, fn {file, _} -> IO.puts("rewrite #{file}") end)
        System.halt(1)

      check? ->
        IO.puts("mica_saas_tests: nothing left to move or rewrite")

      moves == [] and rewrites == [] ->
        IO.puts("mica_saas_tests: nothing left to move or rewrite")

      true ->
        Enum.each(moves, &move/1)
        rewrites = if "--move" in args, do: [], else: pending_rewrites([])
        Enum.each(rewrites, fn {file, source} -> File.write!(file, source) end)

        to_next = Enum.count(moves, fn {_, to} -> String.starts_with?(to, @next_dir) end)

        IO.puts(
          "mica_saas_tests: moved #{length(moves)} files (#{to_next} to core/next/test), " <>
            "rewrote #{length(rewrites)} files"
        )
    end
  end

  defp pending_moves do
    tests =
      for file <- files(@mica),
          String.ends_with?(file, "_test.exs"),
          Regex.match?(@needs_endpoint, File.read!(file)),
          do: file

    support = for path <- @support, file = @mica <> path, File.regular?(file), do: file

    for from <- tests ++ support do
      path = String.replace_prefix(from, @mica, "")
      {from, if(path in @to_next, do: @next_dir, else: @self_dir) <> path}
    end
  end

  defp move({from, to}) do
    if File.exists?(to), do: raise("#{to} exists already; move #{from} by hand")
    File.mkdir_p!(Path.dirname(to))

    case System.cmd("git", ["mv", from, to], stderr_to_stdout: true) do
      {_, 0} -> :ok
      {_, _untracked} -> File.rename!(from, to)
    end
  end

  # {file, new source} of the files in the SaaS test folders that still need it.
  # After a --check, `moves` are the files that would be there.
  defp pending_rewrites(moves) do
    files =
      for {dir, saas} <- @saases, file <- files(dir), do: {file, file, saas}

    moved =
      for {from, to} <- moves,
          {dir, saas} <- @saases,
          String.starts_with?(to, dir),
          do: {to, from, saas}

    for {file, read_from, saas} <- files ++ moved,
        not Regex.match?(@excluded, file),
        source = File.read!(read_from),
        rewritten = rewrite(source, saas),
        rewritten != source,
        uniq: true,
        do: {file, rewritten}
  end

  defp rewrite(source, %{top: top, web: web}) do
    source =
      Enum.reduce(@cases, source, fn name, source ->
        String.replace(source, ~r/\bMicaWeb\.#{name}\b/, "#{web}.#{name}")
      end)

    # As scripts/use_saas_web.exs: a test's own LiveViews use the SaaS's web module.
    source = String.replace(source, @use_mica_web, "use #{web}")

    renames =
      for [_, name] <- Regex.scan(@defmodule, source),
          new = saas_name(name, top, web),
          new != name,
          do: {name, new}

    # The top-level modules and every other use of their exact name in the file,
    # such as a fake module that the test puts in the config.
    Enum.reduce(renames, source, fn {name, new}, source ->
      String.replace(source, ~r/(?<![\w.])#{Regex.escape(name)}(?!\w|\.[A-Z])/, new)
    end)
  end

  defp saas_name(name, top, web) do
    case String.split(name, ".", parts: 2) do
      [first | _] when first in [top, web, "Mix"] -> name
      ["MicaWeb", rest] -> "#{web}.#{rest}"
      ["Mica", rest] -> "#{top}.#{rest}"
      _ -> "#{top}.#{name}"
    end
  end

  defp files(folder) do
    if File.dir?(folder), do: git_files(folder), else: []
  end

  defp git_files(folder) do
    {out, 0} =
      System.cmd("git", ~w(ls-files -z --cached --others --exclude-standard --) ++ [folder])

    out
    |> String.split(<<0>>, trim: true)
    |> Enum.filter(&(Path.extname(&1) in ~w(.ex .exs) and File.regular?(&1)))
  end

  defp root do
    {out, 0} = System.cmd("git", ~w(rev-parse --show-toplevel))
    String.trim(out)
  end
end

MicaSaasTests.main(System.argv())
