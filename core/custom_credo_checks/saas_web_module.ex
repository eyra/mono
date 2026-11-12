defmodule Credo.Check.Warning.SaasWebModule do
  use Credo.Check,
    base_priority: :high,
    category: :warning,
    explanations: [
      check: """
      Nova migration step code-compose. Code of a SaaS uses its own web module, so
      its `~p` is verified against that SaaS's router: `NextWeb` in core/next/,
      `MicaSaasWeb` in core/mica_saas/. `MicaWeb` is Mica's.

      # Bad, in core/next/
      use MicaWeb, :routed_live_view

      # Good
      use NextWeb, :routed_live_view

      Mica's other modules, such as `use MicaWeb.LiveForm`, are fine.
      `elixir scripts/use_saas_web.exs` rewrites the old form.

      Mica has no router, so its code builds paths with `~m` (`MicaWeb.Path`),
      which every SaaS checks against its own router, never with `~p`:

      # Bad, in core/mica/
      ~p"/assignment/\#{assignment}"

      # Good
      ~m"/assignment/\#{assignment}"

      `elixir scripts/mica_paths.exs` rewrites the old form.
      """
    ]

  @web_modules %{"next" => "NextWeb", "mica_saas" => "MicaSaasWeb"}
  # The sigil with any of its delimiters, also inside HEEx templates.
  @sigil_p ~r/~p["'(\[{<|\/]/

  @doc false
  def run(%SourceFile{filename: filename} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    case BoundaryRules.owner(filename) do
      "mica" ->
        for {line_no, line} <- SourceFile.lines(source_file),
            Regex.match?(@sigil_p, line),
            do: sigil_p_issue(issue_meta, line_no)

      owner ->
        case Map.fetch(@web_modules, owner) do
          {:ok, web} -> Credo.Code.prewalk(source_file, &traverse(&1, &2, web, issue_meta))
          :error -> []
        end
    end
  end

  defp traverse({:use, meta, [{:__aliases__, _, [:MicaWeb]} | _]} = ast, issues, web, issue_meta) do
    {ast, [issue(issue_meta, meta[:line], web) | issues]}
  end

  defp traverse(ast, issues, _web, _issue_meta), do: {ast, issues}

  defp issue(issue_meta, line_no, web) do
    format_issue(issue_meta,
      message: "Use #{web}, this SaaS's web module, instead of MicaWeb.",
      trigger: "use MicaWeb",
      line_no: line_no
    )
  end

  defp sigil_p_issue(issue_meta, line_no) do
    format_issue(issue_meta,
      message: "Use ~m (MicaWeb.Path) for Mica's paths, not ~p: Mica has no router.",
      trigger: "~p",
      line_no: line_no
    )
  end
end
