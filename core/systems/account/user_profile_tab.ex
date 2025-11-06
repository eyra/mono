defmodule Systems.Account.UserProfileTab do
  @moduledoc """
  Behaviour for user profile tabs.

  Each tab module must implement:
  - key/0: Returns the unique key for this tab
  - visible?/1: Determines if this tab should be visible for the given user
  - build/2: Builds the tab data structure
  """

  @type user :: Systems.Account.User.t()
  @type fabric :: any()
  @type tab_spec :: %{
          key: atom(),
          id: atom(),
          title: String.t(),
          module: module(),
          params: map()
        }

  @callback key() :: atom()
  @callback visible?(user) :: boolean()
  @callback build(user, fabric) :: tab_spec()
end
