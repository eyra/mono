defmodule Core.Admin do
  def compile(patterns) do
    combined =
      patterns
      |> Enum.map(fn pattern ->
        pattern
        |> Regex.escape()
        |> String.replace("\\*", "[\\w_\.\-]+")
      end)
      |> Enum.join("|")

    Regex.compile!("^#{combined}$")
  end

  def admin?(_compiled, email) when is_nil(email), do: false

  def admin?(%Regex{} = compiled, email) when is_binary(email) do
    Regex.match?(compiled, email)
  end

  def admin?(patterns, email) when is_list(patterns) do
    patterns
    |> compile()
    |> admin?(email)
  end

  def admin?(compiled, %{email: email}) do
    admin?(compiled, email)
  end

  def admin?(email) do
    admin?(email_patterns(), email)
  end

  defp email_patterns do
    Application.get_env(:core, :admins, [])
  end
end
