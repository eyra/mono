defmodule Credo.Check.Warning.NoRepoTransaction do
  use Credo.Check,
    base_priority: :high,
    category: :warning,
    explanations: [
      check: """
      Repo.transaction() should not be used directly. Use Repo.commit() instead.

      Repo.commit() ensures that Observatory updates collected during the transaction
      are properly dispatched after the transaction commits successfully.

      ## Why is this important?

      When using the Signal framework with Observatory for LiveView updates,
      updates must be collected during the transaction and only dispatched after
      the database changes are committed. Using Repo.transaction() directly
      bypasses this mechanism and can lead to race conditions where LiveViews
      try to query data before it's committed.

      ## Examples

      # Bad
      Multi.new()
      |> Multi.update(:model, changeset)
      |> Signal.Public.multi_dispatch({:model, :updated})
      |> Repo.transaction()

      # Good
      Multi.new()
      |> Multi.update(:model, changeset)
      |> Signal.Public.multi_dispatch({:model, :updated})
      |> Repo.commit()

      ## Exceptions

      If you have a specific case where Repo.transaction() must be used directly
      (e.g., in a library that doesn't have access to Repo.commit()), you can
      disable this check for that line:

      # credo:disable-for-next-line Credo.Check.Warning.NoRepoTransaction
      Repo.transaction(multi)
      """
    ]

  @message "Use Repo.commit() instead of Repo.transaction() to ensure Observatory updates are dispatched correctly."

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  # Don't match Repo.transaction() with no arguments - that's not a valid call

  # Match Repo.commit(arg) with one argument
  defp traverse(
         {{:., meta, [{:__aliases__, _, [:Repo]}, :transaction]}, _, [_arg]} = ast,
         issues,
         issue_meta
       ) do
    {ast, [issue_for(issue_meta, meta[:line]) | issues]}
  end

  # Match Repo.commit(arg1, arg2) with two arguments
  defp traverse(
         {{:., meta, [{:__aliases__, _, [:Repo]}, :transaction]}, _, [_arg1, _arg2]} = ast,
         issues,
         issue_meta
       ) do
    {ast, [issue_for(issue_meta, meta[:line]) | issues]}
  end

  # Don't match Core.Repo.transaction() with no arguments - that's not a valid call

  # Match Core.Repo.commit(arg) with one argument
  defp traverse(
         {{:., meta, [{:__aliases__, _, [:Core, :Repo]}, :transaction]}, _, [_arg]} = ast,
         issues,
         issue_meta
       ) do
    {ast, [issue_for(issue_meta, meta[:line]) | issues]}
  end

  # Match Core.Repo.commit(arg1, arg2) with two arguments
  defp traverse(
         {{:., meta, [{:__aliases__, _, [:Core, :Repo]}, :transaction]}, _, [_arg1, _arg2]} = ast,
         issues,
         issue_meta
       ) do
    {ast, [issue_for(issue_meta, meta[:line]) | issues]}
  end

  # Match any module alias ending with Repo.transaction
  defp traverse(
         {{:., meta, [{:__aliases__, _, module_parts}, :transaction]}, _, args} = ast,
         issues,
         issue_meta
       )
       when is_list(module_parts) and is_list(args) do
    if List.last(module_parts) == :Repo do
      {ast, [issue_for(issue_meta, meta[:line]) | issues]}
    else
      {ast, issues}
    end
  end

  # Match direct transaction/1 calls (likely from import Core.Repo)
  # But not when it's inside a type spec (meta will be nil for type specs)
  defp traverse({:transaction, meta, [_arg]} = ast, issues, issue_meta) when is_list(meta) do
    {ast, [issue_for(issue_meta, meta[:line]) | issues]}
  end

  # Match direct transaction/2 calls (likely from import Core.Repo)
  defp traverse({:transaction, meta, [_arg1, _arg2]} = ast, issues, issue_meta)
       when is_list(meta) do
    {ast, [issue_for(issue_meta, meta[:line]) | issues]}
  end

  # Match direct transaction/3 calls (likely from import Core.Repo)
  defp traverse({:transaction, meta, [_arg1, _arg2, _arg3]} = ast, issues, issue_meta)
       when is_list(meta) do
    {ast, [issue_for(issue_meta, meta[:line]) | issues]}
  end

  # Don't match transaction/0 - it's only used in type specs, not actual function calls

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: @message,
      trigger: "transaction",
      line_no: line_no
    )
  end
end
