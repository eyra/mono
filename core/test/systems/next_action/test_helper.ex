defmodule Systems.NextAction.TestHelper do
  import ExUnit.Assertions

  alias Systems.NextAction

  defmacro assert_next_action(user, url) do
    quote bind_quoted: [user: user, url: url] do
      next_actions = NextAction.Public.list_next_actions(user)
      assert next_actions |> Enum.find_value(&(&1[:cta_action] == %{to: url, type: :redirect}))
    end
  end

  defmacro refute_next_action(user, url) do
    quote bind_quoted: [user: user, url: url] do
      next_actions = NextAction.Public.list_next_actions(user)
      refute next_actions |> Enum.find_value(&(&1[:url] == url))
    end
  end
end
