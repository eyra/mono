defprotocol Systems.Account.UserService do
  @spec logged_in?(any) :: boolean
  def logged_in?(state)
end

defimpl Systems.Account.UserService, for: Phoenix.LiveView.Socket do
  def logged_in?(%{assigns: %{__assigns__: %{user: user}}}), do: user != nil
  def logged_in?(%{assigns: %{current_user: _user}}), do: true
  def logged_in?(_), do: false
end

defimpl Systems.Account.UserService, for: Systems.Account.User do
  def logged_in?(_), do: true
end
