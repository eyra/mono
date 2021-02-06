defimpl GreenLight.Principal, for: Atom do
  def id(user) when is_nil(user), do: nil

  def roles(user) when is_nil(user), do: MapSet.new([:visitor])
end

defimpl GreenLight.Principal, for: Link.Users.User do
  def id(user), do: user.id

  def roles(user) do
    roles = if(Link.Users.get_profile(user).researcher, do: [:researcher], else: [])
    MapSet.new([:member | roles])
  end
end

defimpl GreenLight.Principal, for: Plug.Conn do
  def id(conn), do: GreenLight.Principal.id(Pow.Plug.current_user(conn))

  def roles(conn), do: GreenLight.Principal.roles(Pow.Plug.current_user(conn))
end
