defmodule Systems.Account.UserProfilePageBuilder do
  def view_model(user, _assigns) do
    %{
      title: nil,
      user: user,
      active_menu_item: :profile
    }
  end
end
