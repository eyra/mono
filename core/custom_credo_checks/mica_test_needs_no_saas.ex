defmodule Credo.Check.Warning.MicaTestNeedsNoSaas do
  use Credo.Check,
    base_priority: :high,
    category: :warning,
    explanations: [
      check: """
      Nova migration step code-compose. Mica has no router and no endpoint, so a
      test in core/mica/test needs neither. A test that does is a SaaS test: it goes
      to Self's suite, core/mica_saas/test, or to core/next/test when it tests
      Next's behaviour. This check reports, in core/mica/test:

      - the case modules of router and endpoint tests: `ConnCase`, `FeatureCase`
        and `ChannelCase`
      - `Phoenix.ConnTest` and Wallaby
      - `@endpoint`
      - LiveView tests that need an endpoint: `live/2`, `live_isolated/3` and
        `follow_redirect/2`

      # Bad, in core/mica/test/
      use MicaWeb.ConnCase
      {:ok, view, _html} = live(conn, ~m"/assignment/\#{assignment.id}")

      # Good, in core/mica/test/
      use Mica.DataCase
      html = render_component(&Assignment.Html.card/1, assignment: assignment)

      `elixir scripts/mica_saas_tests.exs` moves such tests.
      """
    ]

  @cases [:ConnCase, :FeatureCase, :ChannelCase]
  @endpoint_functions [:live, :live_isolated, :follow_redirect]

  @doc false
  def run(%SourceFile{filename: filename} = source_file, params \\ []) do
    if mica_test?(filename) do
      issue_meta = IssueMeta.for(source_file, params)

      source_file
      |> Credo.Code.prewalk(&traverse(&1, &2, issue_meta))
      |> Enum.uniq_by(&{&1.line_no, &1.trigger})
    else
      []
    end
  end

  defp mica_test?(filename) do
    path = Path.relative_to_cwd(filename)
    BoundaryRules.owner(path) == "mica" and BoundaryRules.test_file?(path)
  end

  defp traverse({:__aliases__, meta, [_ | _] = parts} = ast, issues, issue_meta) do
    case trigger(parts) do
      nil -> {ast, issues}
      trigger -> {ast, [issue(issue_meta, meta[:line], trigger) | issues]}
    end
  end

  defp traverse({:@, meta, [{:endpoint, _, [value]}]} = ast, issues, issue_meta)
       when not is_tuple(value) or elem(value, 0) != :%{} do
    {ast, [issue(issue_meta, meta[:line], "@endpoint") | issues]}
  end

  defp traverse({name, meta, args} = ast, issues, issue_meta)
       when name in @endpoint_functions and is_list(args) and args != [] do
    {ast, [issue(issue_meta, meta[:line], "#{name}") | issues]}
  end

  defp traverse(
         {{:., _, [{:__aliases__, _, [:Phoenix, :LiveViewTest]}, name]}, meta, _args} = ast,
         issues,
         issue_meta
       )
       when name in @endpoint_functions do
    {ast, [issue(issue_meta, meta[:line], "Phoenix.LiveViewTest.#{name}") | issues]}
  end

  defp traverse(ast, issues, _issue_meta), do: {ast, issues}

  defp trigger([:Phoenix, :ConnTest | _]), do: "Phoenix.ConnTest"
  defp trigger([:Wallaby | _]), do: "Wallaby"

  defp trigger(parts) do
    case List.last(parts) do
      name when name in @cases -> Enum.join(parts, ".")
      _ -> nil
    end
  end

  defp issue(issue_meta, line_no, trigger) do
    format_issue(issue_meta,
      message:
        "#{trigger} needs a router or an endpoint: move this test to core/mica_saas/test " <>
          "(or core/next/test), Mica's tests need no SaaS.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
