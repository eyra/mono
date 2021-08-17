defmodule Core.NextActions.Test do
  import ExUnit.Assertions

  alias Core.NextActions

  defmacro assert_next_action(user, url_resolver, url) do
    quote bind_quoted: [user: user, url_resolver: url_resolver, url: url] do
      next_actions = NextActions.list_next_actions(url_resolver, user)
      assert next_actions |> Enum.find_value(&(&1[:url] == url))
    end
  end

  defmacro refute_next_action(user, url_resolver, url) do
    quote bind_quoted: [user: user, url_resolver: url_resolver, url: url] do
      next_actions = NextActions.list_next_actions(url_resolver, user)
      refute next_actions |> Enum.find_value(&(&1[:url] == url))
    end
  end
end
