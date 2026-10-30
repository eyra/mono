# Nova migration step code-rename (docs/nova-migration/plan.md).
#
# Renames, in every text file of the repository:
#   * the OTP app :core to :mica, and Core.* / CoreWeb.* to Mica.* / MicaWeb.*
#   * Next's systems: Systems.<X> defined under core/next becomes Next.Systems.<X>,
#     and the bundle systems Next.<X> (with a Next.<X>.System) become Next.Systems.<X>
#   * Next's frameworks: Frameworks.* defined under core/next becomes Next.Frameworks.*
#   * Next's web shell: Next.Layouts and Next.Menu become NextWeb.*, and CoreWeb.*
#     modules defined under core/next (the feature tests) become NextWeb.*
#   * Self: Self.<X> (with a Self.<X>.System) becomes MicaSaas.Systems.<X>,
#     Self.Layouts and Self.Menu become MicaSaasWeb.*, the rest of Self.* MicaSaas.*
# and moves core/mica/lib/core* and core/mica/test/core* to mica*, and the Self
# Nova snapshots from next/test/snapshots/self to next/test/snapshots/mica_saas.
#
# Unchanged: the release name and binary (bin/core), environment variables, the
# bundle id :self and BUNDLE=self, cookie names, Mica's Systems.* and Frameworks.*.
#
# Idempotent: it only rewrites names that are still old, so it can be re-run on
# any branch, and on a merge that brings old names back.
#
# Usage, from anywhere in the repository:
#   elixir core/scripts/rename_mica.exs            # rename
#   elixir core/scripts/rename_mica.exs --check    # list files with old names, exit 1 if any
# Then, from core/: mix format

defmodule RenameMica do
  @source_exts ~w(.ex .exs .heex .eex .leex)
  @excluded_prefixes [
    "CHANGELOG.md",
    "docs/nova-migration/",
    "core/architecture/",
    "core/priv/static/",
    "core/scripts/rename_mica.exs",
    # Migrates the stored old names, so it names them.
    "core/priv/repo/migrations/20261030120000_rename_stored_module_names.exs"
  ]
  @excluded_exts ~w(.png .jpg .jpeg .gif .ico .webp .svg .woff .woff2 .ttf .otf .eot .pdf .zip
                    .gz .beam .lock .archimate .mp4 .mov)

  # {from, to}: a file, or a folder (trailing slash), relative to the repository root.
  @moves [
    {"core/mica/lib/core.ex", "core/mica/lib/mica.ex"},
    {"core/mica/lib/core_web.ex", "core/mica/lib/mica_web.ex"},
    {"core/mica/lib/core/", "core/mica/lib/mica/"},
    {"core/mica/lib/core_web/", "core/mica/lib/mica_web/"},
    {"core/mica/test/core/", "core/mica/test/mica/"},
    {"core/mica/test/core_web/", "core/mica/test/mica_web/"},
    {"core/custom_credo_checks/core_env_access.ex",
     "core/custom_credo_checks/mica_env_access.ex"},
    {"core/next/test/snapshots/self/", "core/next/test/snapshots/mica_saas/"}
  ]

  # Seeds for the sets derived from the tree, so a branch that lacks a module still
  # renames references to it.
  @next_systems ~w(Annotation Citizen Graphite Ontology Onyx Paper Probe Student Zircon)
  @next_bundle_systems ~w(Account E2E Panl WellKnown)
  # Frameworks.E2E is Next's whole namespace; Frameworks.Concept is Mica's.
  @next_frameworks ~w(E2E Concept.ScreeningAgent)
  # Exact modules: Mica has its own CoreWeb.Features.* tests.
  @next_web ~w(Features.AuthIdentifyErrorTest Features.EmailCaptureTest Features.OnboardingTest
                Features.PanlFinishedCTATest Features.PanlSignupLocaleTest
                Features.PanlStudyAdvertTest Features.ProbeCreateTest
                Features.PromotionApplyAsVisitorTest)
  @self_systems ~w(Account)

  # A module name starts here: not inside another name, or right after `Elixir.`.
  @b "(?:(?<![\\w.])|(?<=Elixir\\.))"

  def main(args) do
    root = root()
    File.cd!(root)
    check? = "--check" in args

    moves = pending_moves()
    unless check?, do: Enum.each(moves, &move/1)

    rules = rules(sets())

    changed =
      for file <- files(),
          text?(file),
          content = File.read!(file),
          String.valid?(content),
          renamed = rewrite(file, content, rules),
          renamed != content do
        unless check?, do: File.write!(file, renamed)
        file
      end

    cond do
      check? and (moves != [] or changed != []) ->
        Enum.each(moves, fn {from, to} -> IO.puts("move #{from} -> #{to}") end)
        Enum.each(changed, &IO.puts("old names in #{&1}"))
        System.halt(1)

      check? ->
        IO.puts("rename_mica: nothing left to rename")

      true ->
        IO.puts("rename_mica: moved #{length(moves)} files, rewrote #{length(changed)} files")
        IO.puts("rename_mica: now run `mix format` in core/")
    end
  end

  defp root do
    {out, 0} = System.cmd("git", ~w(rev-parse --show-toplevel))
    String.trim(out)
  end

  defp files do
    {out, 0} = System.cmd("git", ~w(ls-files -z --cached --others --exclude-standard))

    out
    |> String.split(<<0>>, trim: true)
    |> Enum.uniq()
    |> Enum.filter(&File.regular?/1)
  end

  defp text?(file) do
    not Enum.any?(@excluded_prefixes, &String.starts_with?(file, &1)) and
      Path.extname(file) not in @excluded_exts
  end

  # --- moves ---------------------------------------------------------------------

  defp pending_moves do
    all = files()

    for {from, to} <- @moves, file <- all, target = target(file, from, to), target do
      {file, target}
    end
  end

  defp target(file, from, to) do
    cond do
      String.ends_with?(from, "/") and String.starts_with?(file, from) ->
        to <> String.replace_prefix(file, from, "")

      file == from ->
        to

      true ->
        nil
    end
  end

  defp move({from, to}) do
    if File.exists?(to) do
      IO.puts(:stderr, "rename_mica: #{to} exists, left #{from} in place; merge them by hand")
    else
      File.mkdir_p!(Path.dirname(to))
      File.rename!(from, to)
      remove_empty_dirs(Path.dirname(from))
    end
  end

  defp remove_empty_dirs(dir) do
    if dir not in [".", ""] and File.ls!(dir) == [] do
      File.rmdir!(dir)
      remove_empty_dirs(Path.dirname(dir))
    end
  end

  # --- the module sets, from the tree --------------------------------------------

  defp sets do
    next = defined("core/next")
    self = defined("core/mica_saas")
    mica = defined("core/mica")

    mica_systems = for ["Systems", x | _] <- mica, uniq: true, do: x

    %{
      next_systems:
        union(@next_systems, for(["Systems", x | _] <- next, x not in mica_systems, do: x)),
      next_bundle_systems:
        union(@next_bundle_systems, for(["Next", x, "System"] <- next, x != "Systems", do: x)),
      next_frameworks:
        union(@next_frameworks, for(["Frameworks" | rest] <- next, do: Enum.join(rest, "."))),
      next_web: union(@next_web, for(["CoreWeb" | rest] <- next, do: Enum.join(rest, "."))),
      next_core: for(["Core" | rest] <- next, uniq: true, do: Enum.join(rest, ".")),
      self_systems:
        union(@self_systems, for(["Self", x, "System"] <- self, x != "Systems", do: x)),
      self_core: for(["Core" | rest] <- self, uniq: true, do: Enum.join(rest, ".")),
      self_web: for(["CoreWeb" | rest] <- self, uniq: true, do: Enum.join(rest, "."))
    }
  end

  # The top-level module names defined in the Elixir files under `dir`, split.
  defp defined(dir) do
    for file <- Path.wildcard(dir <> "/**/*.{ex,exs}"),
        [_, name] <- Regex.scan(~r/^defmodule\s+([A-Z][\w.]*)/m, File.read!(file)),
        uniq: true,
        do: String.split(name, ".")
  end

  defp union(seed, found), do: Enum.uniq(seed ++ found)

  defp alt(names),
    do: names |> Enum.sort_by(&(-String.length(&1))) |> Enum.map_join("|", &Regex.escape/1)

  # --- the rules -----------------------------------------------------------------

  # {regex, replacement, :all | :source | :doc}, applied in order. Every rule only
  # matches an old name, so applying them again changes nothing.
  defp rules(sets) do
    b = @b

    explicit = [
      {"Next.WellKnownControllerTest", "Next.Systems.WellKnown.ControllerTest"},
      {"Next.WellKnownController", "Next.Systems.WellKnown.Controller"},
      {"Annotation.PublicTest", "Next.Systems.Annotation.PublicTest"},
      {"Ontology.PublicTest", "Next.Systems.Ontology.PublicTest"},
      {"Mix.Tasks.Core.Graphite", "Mix.Tasks.Next.Graphite"}
    ]

    Enum.map(explicit, fn {from, to} -> {re(b <> Regex.escape(from) <> "\\b"), to, :all} end) ++
      [
        {~r/\bCoreEnvAccess\b/, "MicaEnvAccess", :all},
        # Router scopes on a SaaS namespace, with routes relative to it
        # (`scope "/", Next do ... Account.SigninPage`).
        {~r/(\bscope\(?\s*"[^"]*",\s*)Next(?=\s+do\b)/, "\\1Next.Systems", :source},
        {~r/(\bscope\(?\s*"[^"]*",\s*)Self(?=\s+do\b)/, "\\1MicaSaas.Systems", :source},
        {re(b <> "WellKnownController\\b"), "WellKnown.Controller", :source},
        {~r/\bmix core\.graphite\./, "mix next.graphite.", :all},
        {~r/(?<![\w])core_env_access\b/, "mica_env_access", :all},
        {re(b <> "Systems\\.(#{alt(sets.next_systems)})\\b"), "Next.Systems.\\1", :all},
        {re(b <> "Next\\.(#{alt(sets.next_bundle_systems)})\\b"), "Next.Systems.\\1", :all},
        {re(b <> "Next\\.(Layouts|Menu)\\b"), "NextWeb.\\1", :all},
        {re(b <> "Frameworks\\.(#{alt(sets.next_frameworks)})\\b"), "Next.Frameworks.\\1", :all},
        {re(b <> "Self\\.(#{alt(sets.self_systems)})\\b"), "MicaSaas.Systems.\\1", :all},
        {re(b <> "Self\\.(Layouts|Menu)\\b"), "MicaSaasWeb.\\1", :all},
        {re(b <> "Self\\.(?=[A-Z])"), "MicaSaas.", :all},
        {re(b <> "CoreWeb\\.(#{alt(sets.next_web)})\\b"), "NextWeb.\\1", :all}
      ] ++
      saas_core_rules(b, sets.next_core, "Core", "Next") ++
      saas_core_rules(b, sets.self_core, "Core", "MicaSaas") ++
      saas_core_rules(b, sets.self_web, "CoreWeb", "MicaSaasWeb") ++
      [
        {re(b <> "CoreWeb\\b"), "MicaWeb", :all},
        {re(b <> "Core(?=\\.[A-Z{])"), "Mica", :all},
        # A bare `Core` is the module in Elixir code (`use Core, :public`, `:Core`).
        {re(b <> "Core\\b(?!\\.\\w)"), "Mica", :source},
        {~r/`Core`/, "`Mica`", :doc},
        {~r/\buse Core\b/, "use Mica", :doc},
        {~r/"Core"/, "\"Mica\"", :json},
        # The OTP app. Not `core:` keys (the release name) or `_core_*` cookie names.
        {~r/(?<![\w:]):core\b(?![\w@-])/, ":mica", :all},
        # Paths that carry the name, including the build path of the app.
        {~r/(?<![\w-])(lib|test)\/core(_web)?(?=\/|\.ex\b)/, "\\1/mica\\2", :all},
        {~r/\bsnapshots\/self\b/, "snapshots/mica_saas", :all}
      ]
  end

  defp saas_core_rules(_b, [], _from, _to), do: []

  defp saas_core_rules(b, names, from, to),
    do: [{re(b <> from <> "\\.(#{alt(names)})\\b"), to <> ".\\1", :all}]

  defp re(source), do: Regex.compile!(source)

  # --- rewriting -----------------------------------------------------------------

  defp rewrite(file, content, rules) do
    kind = kind(file)
    content = if kind == :source, do: split_groups(content, rules), else: content
    content = config_snapshot(file, content)

    Enum.reduce(rules, content, fn {regex, replacement, applies}, acc ->
      if applies?(applies, kind), do: Regex.replace(regex, acc, replacement), else: acc
    end)
  end

  defp kind(file) do
    cond do
      Path.extname(file) in @source_exts -> :source
      Path.extname(file) == ".json" -> :json
      true -> :doc
    end
  end

  defp applies?(:all, _kind), do: true
  defp applies?(:doc, kind), do: kind in [:doc, :json]
  defp applies?(applies, kind), do: applies == kind

  # The app key in the `mix config.snapshot` fixtures.
  defp config_snapshot(file, content) do
    if String.starts_with?(file, "core/next/test/config/snapshots/"),
      do: Regex.replace(~r/^(\s*)core: \[/m, content, "\\1mica: ["),
      else: content
  end

  # `alias Systems.{Fund, Paper}`: when the members get different new prefixes, one
  # alias per new prefix. When they all get the same new prefix, the group keeps its
  # members under that prefix.
  defp split_groups(content, rules) do
    Regex.replace(
      ~r/^([ \t]*)(alias|require)\s+([A-Z][\w.]*)\.\{([^{}]*)\}/m,
      content,
      fn whole, indent, keyword, base, body ->
        members =
          body |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))

        if Enum.all?(members, &Regex.match?(~r/^[A-Z][\w.]*$/, &1)) do
          renamed = Enum.map(members, &{&1, rename_name(base <> "." <> &1, rules)})
          prefixes = Enum.map(renamed, fn {member, new} -> prefix(new, member) end)

          case Enum.uniq(prefixes) do
            [^base] -> whole
            [prefix] when prefix != nil -> String.replace(whole, base <> ".{", prefix <> ".{")
            _ -> regroup(indent, keyword, renamed)
          end
        else
          whole
        end
      end
    )
  end

  defp prefix(new, member) do
    if String.ends_with?(new, "." <> member),
      do: String.replace_suffix(new, "." <> member, ""),
      else: nil
  end

  defp regroup(indent, keyword, renamed) do
    renamed
    |> Enum.group_by(fn {member, new} -> prefix(new, member) end)
    |> Enum.sort_by(fn {prefix, _} -> prefix || "" end)
    |> Enum.flat_map(fn
      {nil, members} ->
        for {member, new} <- members do
          short = member |> String.split(".") |> List.last()
          "#{indent}#{keyword} #{new}, as: #{short}"
        end

      {prefix, [{member, _new}]} ->
        ["#{indent}#{keyword} #{prefix}.#{member}"]

      {prefix, members} ->
        ["#{indent}#{keyword} #{prefix}.{#{Enum.map_join(members, ", ", &elem(&1, 0))}}"]
    end)
    |> Enum.join("\n")
  end

  defp rename_name(name, rules) do
    Enum.reduce(rules, name, fn {regex, replacement, applies}, acc ->
      if applies in [:all, :source], do: Regex.replace(regex, acc, replacement), else: acc
    end)
  end
end

RenameMica.main(System.argv())
