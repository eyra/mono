defmodule Core.Admin do
  def emails do
    Application.get_env(:core, :admins, MapSet.new())
  end

  def admin?(email) when is_nil(email), do: false

  def admin?(email) when is_binary(email) do
    MapSet.member?(emails(), email)
  end

  def admin?(%{email: email}) do
    admin?(email)
  end
end
