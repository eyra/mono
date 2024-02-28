defprotocol CoreWeb.User.Service do
  @spec logged_in?(any) :: boolean
  def logged_in?(state)
end

defimpl CoreWeb.User.Service, for: Phoenix.LiveView.Socket do
  def logged_in?(%{assigns: %{__assigns__: %{user: user}}}), do: user != nil
  def logged_in?(%{assigns: %{current_user: _user}}), do: true
  def logged_in?(_), do: false
end

defimpl CoreWeb.User.Service, for: Core.Accounts.User do
  def logged_in?(_), do: true
end
