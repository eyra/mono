defimpl GreenLight.Principal, for: Atom do
  def id(user) when is_nil(user), do: nil

  def roles(user) when is_nil(user), do: MapSet.new([:visitor])
end

defimpl GreenLight.Principal, for: Core.Accounts.User do
  def id(user), do: user.id

  def roles(user) do
    MapSet.new([:member])
    |> add_role_when(:researcher, user.researcher)
    |> add_role_when(:student, user.student)
    |> add_role_when(:admin, Core.Admin.admin?(user))
  end

  defp add_role_when(roles, role, flag) do
    if flag, do: MapSet.put(roles, role), else: roles
  end
end

defimpl GreenLight.Principal, for: Plug.Conn do
  def id(%{assigns: %{current_user: user}}), do: GreenLight.Principal.id(user)
  def roles(%{assigns: %{current_user: user}}), do: GreenLight.Principal.roles(user)
end

defimpl GreenLight.Principal, for: Phoenix.LiveView.Socket do
  def id(%{assigns: %{current_user: user}}), do: GreenLight.Principal.id(user)
  def id(_), do: GreenLight.Principal.id(nil)
  def roles(%{assigns: %{current_user: user}}), do: GreenLight.Principal.roles(user)
  def roles(_), do: GreenLight.Principal.roles(nil)
end
