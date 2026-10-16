defmodule Credo.Check.Warning.MicaBoundary do
  use Credo.Check,
    base_priority: :high,
    category: :warning,
    param_defaults: [
      # Namespaces of the code in each root (paths relative to core/).
      namespaces: %{
        "next/" => [
          "Next",
          "Systems.Student",
          "Systems.Citizen",
          "Systems.Graphite",
          "Systems.Zircon",
          "Systems.Paper",
          "Systems.Annotation",
          "Systems.Ontology",
          "Systems.Onyx",
          "Frameworks.Concept.ScreeningAgent",
          "Frameworks.E2E.Controller"
        ],
        "mica_saas/" => ["Self"]
      },
      # Root => roots it may not reference.
      forbidden: %{
        "mica/" => ["next/", "mica_saas/"],
        "next/" => ["mica_saas/"],
        "mica_saas/" => ["next/"]
      },
      allowlist_file: "boundary_allowlist.exs"
    ],
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
      Files listed in boundary_allowlist.exs are existing violations and are skipped.
      """
    ]

  @doc false
  def run(%SourceFile{filename: filename} = source_file, params \\ []) do
    root = root(filename, params)

    if (root && not test_file?(filename, root)) and not allowlisted?(filename, params) do
      issue_meta = IssueMeta.for(source_file, params)
      namespaces = forbidden_namespaces(root, params)

      module_issues = Credo.Code.prewalk(source_file, &traverse(&1, &2, namespaces, issue_meta))
      literals = if root == "mica/", do: literal_issues(source_file, issue_meta), else: []
      module_issues ++ literals
    else
      []
    end
  end

  defp traverse({:__aliases__, meta, parts} = ast, issues, namespaces, issue_meta)
       when is_list(parts) do
    name = if Enum.all?(parts, &is_atom/1), do: Enum.join(parts, ".")

    case name && Enum.find(namespaces, fn {_root, ns} -> in_namespace?(name, ns) end) do
      {root, _} ->
        {ast, [issue(issue_meta, meta[:line], name, "references a module of #{root}") | issues]}

      _ ->
        {ast, issues}
    end
  end

  defp traverse(ast, issues, _namespaces, _issue_meta), do: {ast, issues}

  # Matches on the full alias only; `alias Systems.{Student, ...}` and short
  # aliases resolved later are left to the xref script in CI.
  defp in_namespace?(name, namespaces) do
    Enum.any?(namespaces, &(name == &1 or String.starts_with?(name, &1 <> ".")))
  end

  defp literal_issues(source_file, issue_meta) do
    source_file
    |> SourceFile.lines()
    |> Enum.flat_map(fn {line_no, line} ->
      for {label, regex} <- literals(), Regex.match?(regex, line) do
        issue(issue_meta, line_no, label, "hard-codes an instance specific")
      end
    end)
  end

  defp literals do
    [
      {":panl", ~r/:panl\b/},
      {"\"Panl\"", ~r/"(Panl|PaNL|PANL)"/},
      {"panl.nl", ~r/panl\.nl/},
      {"eyra.co", ~r/eyra\.co\b/},
      {"@eyra.service", ~r/@eyra\.service/},
      {"VU study code", ~r/\bvu_sbe_\w+|\bgenerate_vu\b|VUDaySchedule/}
    ]
  end

  defp root(filename, params) do
    params
    |> Params.get(:forbidden, __MODULE__)
    |> Map.keys()
    |> Enum.find(&String.starts_with?(filename, &1))
  end

  defp forbidden_namespaces(root, params) do
    namespaces = Params.get(params, :namespaces, __MODULE__)

    params
    |> Params.get(:forbidden, __MODULE__)
    |> Map.fetch!(root)
    |> Enum.map(&{&1, Map.get(namespaces, &1, [])})
  end

  defp test_file?(filename, root), do: String.starts_with?(filename, root <> "test/")

  defp allowlisted?(filename, params) do
    file = Params.get(params, :allowlist_file, __MODULE__)

    case File.exists?(file) && Code.eval_file(file) do
      {list, _} -> Enum.any?(list, fn {path, _kind, _reason} -> path == filename end)
      _ -> false
    end
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
