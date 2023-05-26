defmodule Systems.Admin.Public do
  def compile(patterns) do
    combined =
      Enum.map_join(patterns, "|", fn pattern ->
        pattern
        |> Regex.escape()
        |> String.replace("\\*", "[\\w_\.\-]+")
      end)

    Regex.compile!("^#{combined}$")
  end

  def admin?(_compiled, email) when is_nil(email), do: false

  def admin?(%Regex{} = compiled, email) when is_binary(email) do
    Regex.match?(compiled, email)
  end

  def admin?([_ | _] = patterns, email) when is_binary(email) do
    admin?(compile(patterns), email)
  end

  def admin?(patterns, email) when is_list(patterns) do
    patterns
    |> compile()
    |> admin?(email)
  end

  def admin?(compiled, %{email: email}) do
    admin?(compiled, email)
  end

  def admin?(%{email: email}) do
    admin?(email)
  end

  def admin?(email) when is_binary(email) do
    admin?(email_patterns(), email)
  end

  def admin?(_), do: false

  defp email_patterns do
    Application.get_env(:core, :admins, [])
  end
end
