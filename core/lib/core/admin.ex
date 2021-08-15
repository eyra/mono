defmodule Core.Admin do
  def admin?(email) when is_nil(email), do: false

  def admin?(email) when is_binary(email) do
    Application.get_env(:core, :admins, MapSet.new()) |> MapSet.member?(email)
  end

  def admin?(%{email: email}) do
    admin?(email)
  end
end
