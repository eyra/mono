defmodule Core.NextActionsTest do
  use Core.DataCase
  alias Core.Factories

  alias Core.NextActions

  defmodule SomeAction do
    @behaviour Core.NextActions.ViewModel

    @impl Core.NextActions.ViewModel
    def to_view_model(url_resolver, count, _params) do
      %{
        title: "Test: #{count}",
        description: "Testing",
        cta: "Open test",
        url: url_resolver.()
      }
    end
  end

  setup do
    {:ok, user: Factories.insert!(:member), url_resolver: fn -> "http://example.org" end}
  end

  describe "list_next_actions/2" do
    test "show the users actions", %{user: user, url_resolver: url_resolver} do
      NextActions.create_next_action(user, SomeAction)
      assert [_] = NextActions.list_next_actions(url_resolver, user)
      other_user = Factories.insert!(:member)
      assert [] = NextActions.list_next_actions(url_resolver, other_user)
    end

    test "can filter actions by content node", %{user: user, url_resolver: url_resolver} do
      content_node = Factories.insert!(:content_node)
      NextActions.create_next_action(user, SomeAction, content_node: content_node)
      assert [_] = NextActions.list_next_actions(url_resolver, user, content_node)
      # Filter by another node shows no results
      assert [] =
               NextActions.list_next_actions(url_resolver, user, Factories.insert!(:content_node))
    end
  end

  describe "create_next_action/3" do
    test "add creates a new next action", %{user: user, url_resolver: url_resolver} do
      NextActions.create_next_action(user, SomeAction)
      assert [_] = NextActions.list_next_actions(url_resolver, user)
    end

    test "add the same action multiple times increases it's count", %{
      user: user,
      url_resolver: url_resolver
    } do
      NextActions.create_next_action(user, SomeAction)
      NextActions.create_next_action(user, SomeAction)
      assert [%{title: "Test: 2"}] = NextActions.list_next_actions(url_resolver, user)
    end

    test "add creates a new next action on a content node", %{
      user: user,
      url_resolver: url_resolver
    } do
      content_node = Factories.insert!(:content_node)
      NextActions.create_next_action(user, SomeAction, content_node: content_node)
      assert [_] = NextActions.list_next_actions(url_resolver, user)
    end

    test "add the same action multiple times on the same content node increases it's count", %{
      user: user,
      url_resolver: url_resolver
    } do
      content_node = Factories.insert!(:content_node)
      other_node = Factories.insert!(:content_node)
      NextActions.create_next_action(user, SomeAction, content_node: content_node)
      NextActions.create_next_action(user, SomeAction, content_node: other_node)
      NextActions.create_next_action(user, SomeAction, content_node: content_node)

      assert [%{title: "Test: 2"}] =
               NextActions.list_next_actions(url_resolver, user, content_node)

      assert [%{title: "Test: 1"}] = NextActions.list_next_actions(url_resolver, user, other_node)
    end
  end

  describe "clear_next_action/3" do
    test "clearing a non existing action does nothing", %{user: user, url_resolver: _url_resolver} do
      NextActions.clear_next_action(user, :does_not_exist)

      NextActions.clear_next_action(user, :with_content_node, Factories.insert!(:content_node))
    end

    test "clearing an existing action removes it from the list", %{
      user: user,
      url_resolver: url_resolver
    } do
      NextActions.create_next_action(user, SomeAction)
      assert [_] = NextActions.list_next_actions(url_resolver, user)
      NextActions.clear_next_action(user, SomeAction)
      assert [] = NextActions.list_next_actions(url_resolver, user)
    end

    test "clearing an existing action with a content node removes it from the list", %{
      user: user,
      url_resolver: url_resolver
    } do
      content_node = Factories.insert!(:content_node)
      NextActions.create_next_action(user, SomeAction, content_node: content_node)
      assert [_] = NextActions.list_next_actions(url_resolver, user, content_node)
      NextActions.clear_next_action(user, SomeAction, content_node)
      assert [] = NextActions.list_next_actions(url_resolver, user, content_node)
    end
  end
end
