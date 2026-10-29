defmodule Credo.Check.Warning.MicaBoundary do
  use Credo.Check,
    base_priority: :high,
    category: :warning,
    param_defaults: [allowlist_file: "boundary_allowlist.exs"],
    explanations: [
      check: """
      Nova migration plan, rule 2. Mica (core/mica/) may not depend on any SaaS,
      and a SaaS may not depend on another SaaS: code in core/mica/ must not name
      modules from core/next/ (Eyra's Next) or core/mica_saas/ (the Self reference
      SaaS), and core/next/ and core/mica_saas/ must not name each other's modules.
      Code in core/mica/ must also not hard-code PaNL, VU or Eyra specifics. Use an
      extension point or config.

      This check gives early feedback in the editor and in `mix credo`.
      CI runs scripts/boundary_check.exs, which uses `mix xref` and is authoritative.
      Both take their roots, namespaces and literals from scripts/boundary_rules.ex.
      The kinds boundary_allowlist.exs lists for a file are existing violations and
      are skipped; other kinds in that file are still reported.
      """
    ]

  # Reads the allowlist and derives the namespaces once per run, not per file.
  @impl true
  def run_on_all_source_files(exec, source_files, params) do
    super(exec, source_files, Keyword.put(params, :boundary, context(params)))
  end

  @doc false
  def run(%SourceFile{filename: filename} = source_file, params \\ []) do
    owner = BoundaryRules.owner(filename)

    if owner && not BoundaryRules.test_file?(filename) do
      %{allowlist: allowlist, namespaces: namespaces} =
        Keyword.get_lazy(params, :boundary, fn -> context(params) end)

      issue_meta = IssueMeta.for(source_file, params)
      skipped = for {^filename, kind} <- allowlist, into: MapSet.new(), do: kind

      literals =
        if owner == "mica", do: literal_issues(source_file, skipped, issue_meta), else: []

      module_issues(source_file, owner, skipped, namespaces, issue_meta) ++ literals
    else
      []
    end
  end

  # Namespaces derived from the defmodules in the roots, as the CI script does.
  defp context(params) do
    owners = BoundaryRules.roots() |> Map.values() |> Enum.uniq()

    %{
      allowlist:
        params
        |> Params.get(:allowlist_file, __MODULE__)
        |> BoundaryRules.read_allowlist()
        |> Map.keys(),
      namespaces: Map.new(owners, &{&1, BoundaryRules.namespaces(&1)})
    }
  end

  defp module_issues(source_file, owner, skipped, namespaces, issue_meta) do
    targets =
      for to <- BoundaryRules.forbidden(owner),
          not MapSet.member?(skipped, BoundaryRules.kind(to, "reference")),
          not MapSet.member?(skipped, BoundaryRules.kind(to, "name")),
          do: {to, Map.fetch!(namespaces, to)}

    lines = SourceFile.lines(source_file)

    for {name, line} <- BoundaryRules.names(SourceFile.source(source_file)),
        {to, namespaces} <- targets,
        BoundaryRules.in_namespace?(name, namespaces) do
      issue(issue_meta, line || line_of(lines, name), name, "references a module of #{to}/")
    end
  end

  defp literal_issues(source_file, skipped, issue_meta) do
    for {line_no, line} <- SourceFile.lines(source_file),
        {kind, regex} <- BoundaryRules.literals(),
        not MapSet.member?(skipped, kind),
        [match | _] <- [Regex.run(regex, line)] do
      issue(issue_meta, line_no, match, "hard-codes an instance specific")
    end
  end

  # `:"Elixir.…"` atoms carry no line.
  defp line_of(lines, name) do
    Enum.find_value(lines, 1, fn {line_no, line} -> String.contains?(line, name) && line_no end)
  end

  defp issue(issue_meta, line_no, trigger, what) do
    format_issue(issue_meta,
      message:
        "Boundary: this code #{what} (#{trigger}). Use an extension point or config instead.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
