defmodule Credo.Check.Warning.MicaEnvAccess do
  use Credo.Check,
    base_priority: :high,
    category: :warning,
    param_defaults: [
      # Paths relative to core/ that may name the application directly.
      allowed: ["mica/lib/mica/env.ex"]
    ],
    explanations: [
      check: """
      Read and write the application config through `Mica.Env`, not through
      `Application.*_env(:mica, ...)`. `Mica.Env` is the one place that names the
      OTP application, so renaming it (Nova migration step code-rename) only
      changes that module.

      # Bad
      Application.get_env(:mica, :base_url)
      @policy_urls Application.compile_env(:mica, :policy_urls)

      # Good
      Mica.Env.get(:base_url)
      require Mica.Env
      @policy_urls Mica.Env.compile_env(:policy_urls)

      Config files and tests are not checked.
      """
    ]

  @doc false
  def run(%SourceFile{filename: filename} = source_file, params \\ []) do
    if test_file?(filename) or filename in Params.get(params, :allowed, __MODULE__) do
      []
    else
      issue_meta = IssueMeta.for(source_file, params)
      Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
    end
  end

  defp traverse(
         {{:., _, [{:__aliases__, _, [:Application]}, fun]}, meta, [:mica | _]} = ast,
         issues,
         issue_meta
       ) do
    {ast, [issue(issue_meta, meta[:line], "Application.#{fun}") | issues]}
  end

  defp traverse(
         {:|>, _, [:mica, {{:., _, [{:__aliases__, _, [:Application]}, fun]}, meta, _}]} = ast,
         issues,
         issue_meta
       ) do
    {ast, [issue(issue_meta, meta[:line], "Application.#{fun}") | issues]}
  end

  defp traverse(ast, issues, _issue_meta), do: {ast, issues}

  defp test_file?(filename), do: String.contains?(filename, "/test/")

  defp issue(issue_meta, line_no, trigger) do
    format_issue(issue_meta,
      message: "Use Mica.Env or Mica.Env.app() instead of #{trigger}(:mica, ...).",
      trigger: trigger,
      line_no: line_no
    )
  end
end
