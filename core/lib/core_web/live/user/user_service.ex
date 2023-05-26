defprotocol CoreWeb.User.Service do
  @spec is_logged_in?(any) :: boolean
  def is_logged_in?(state)
end

defimpl CoreWeb.User.Service, for: Phoenix.LiveView.Socket do
  def is_logged_in?(%{assigns: %{__assigns__: %{user: user}}}), do: user != nil
  def is_logged_in?(%{assigns: %{current_user: _user}}), do: true
  def is_logged_in?(_), do: false
end

defimpl CoreWeb.User.Service, for: Core.Accounts.User do
  def is_logged_in?(_), do: true
end
