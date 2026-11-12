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
      """
    ]

  @web_modules %{"next" => "NextWeb", "mica_saas" => "MicaSaasWeb"}

  @doc false
  def run(%SourceFile{filename: filename} = source_file, params \\ []) do
    case Map.fetch(@web_modules, BoundaryRules.owner(filename)) do
      {:ok, web} ->
        issue_meta = IssueMeta.for(source_file, params)
        Credo.Code.prewalk(source_file, &traverse(&1, &2, web, issue_meta))

      :error ->
        []
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
end
