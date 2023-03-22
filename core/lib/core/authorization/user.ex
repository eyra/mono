defimpl Frameworks.GreenLight.Principal, for: Atom do
  def id(user) when is_nil(user), do: nil

  def roles(user) when is_nil(user), do: MapSet.new([:visitor])
end

defimpl Frameworks.GreenLight.Principal, for: Core.Accounts.User do
  def id(user), do: user.id

  def roles(user) do
    MapSet.new([:member])
    |> add_role_when(:researcher, user.researcher)
    |> add_role_when(:student, user.student)
    |> add_role_when(:admin, Systems.Admin.Public.admin?(user))
  end

  defp add_role_when(roles, role, flag) do
    if flag, do: MapSet.put(roles, role), else: roles
  end
end

defimpl Frameworks.GreenLight.Principal, for: Plug.Conn do
  alias Frameworks.GreenLight.Principal
  def id(%{assigns: %{current_user: user}}), do: Principal.id(user)
  def roles(%{assigns: %{current_user: user}}), do: Principal.roles(user)
end

defimpl Frameworks.GreenLight.Principal, for: Phoenix.LiveView.Socket do
  alias Frameworks.GreenLight.Principal
  def id(%{assigns: %{current_user: user}}), do: Principal.id(user)
  def id(_), do: Principal.id(nil)
  def roles(%{assigns: %{current_user: user}}), do: Principal.roles(user)
  def roles(_), do: Principal.roles(nil)
end
