defmodule Systems.NextAction.TestHelper do
  import ExUnit.Assertions

  alias Systems.NextAction

  defmacro assert_next_action(user, url_resolver, url) do
    quote bind_quoted: [user: user, url_resolver: url_resolver, url: url] do
      next_actions = NextAction.Public.list_next_actions(url_resolver, user)
      assert next_actions |> Enum.find_value(&(&1[:cta_action] == %{to: url, type: :redirect}))
    end
  end

  defmacro refute_next_action(user, url_resolver, url) do
    quote bind_quoted: [user: user, url_resolver: url_resolver, url: url] do
      next_actions = NextAction.Public.list_next_actions(url_resolver, user)
      refute next_actions |> Enum.find_value(&(&1[:url] == url))
    end
  end
end
