defmodule Systems.Account.Page.Tab do
  @moduledoc """
  Behaviour for tabs hosted by `Systems.Account.Page` (Profile, Features, …).

  Each tab module must implement:
  - key/0: Returns the unique key for this tab
  - visible?/1: Determines if this tab should be visible for the given user
  - build/2: Builds the tab data structure with a LiveNest element
  """

  @type user :: Systems.Account.User.t()
  @type live_context :: %Frameworks.Concept.LiveContext{data: map()}
  @type tab_spec :: %{
          id: atom(),
          title: String.t(),
          type: atom(),
          element: LiveNest.Element.t(),
          ready?: boolean()
        }

  @callback key() :: atom()
  @callback visible?(user) :: boolean()
  @callback build(user, live_context) :: tab_spec()
end
