defmodule Core.Admin do
  def compile(patterns) do
    patterns
    |> Enum.map(fn pattern ->
      pattern
      |> Regex.escape()
      |> String.replace("\\*", "\\w+")
    end)
    |> Enum.join("|")
    |> Regex.compile!()
  end

  def admin?(_compiled, email) when is_nil(email), do: false

  def admin?(compiled, email) when is_binary(email) do
    Regex.match?(compiled, email)
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
