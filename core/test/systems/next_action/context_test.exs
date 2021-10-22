defmodule Systems.NextAction.ContextTest do
  use Core.DataCase
  alias Core.Factories

  alias Systems.NextAction.Context

  defmodule SomeAction do
    @behaviour Systems.NextAction.ViewModel

    @impl Systems.NextAction.ViewModel
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
      Context.create_next_action(user, SomeAction)
      assert [_] = Context.list_next_actions(url_resolver, user)
      other_user = Factories.insert!(:member)
      assert [] = Context.list_next_actions(url_resolver, other_user)
    end

    test "can filter actions by content node", %{user: user, url_resolver: url_resolver} do
      content_node = Factories.insert!(:content_node)
      Context.create_next_action(user, SomeAction, content_node: content_node)
      assert [_] = Context.list_next_actions(url_resolver, user, content_node)
      # Filter by another node shows no results
      assert [] = Context.list_next_actions(url_resolver, user, Factories.insert!(:content_node))
    end
  end

  describe "create_next_action/3" do
    test "add creates a new next action", %{user: user, url_resolver: url_resolver} do
      Context.create_next_action(user, SomeAction)
      assert [_] = Context.list_next_actions(url_resolver, user)
    end

    test "add the same action multiple times increases it's count", %{
      user: user,
      url_resolver: url_resolver
    } do
      Context.create_next_action(user, SomeAction)
      Context.create_next_action(user, SomeAction)
      assert [%{title: "Test: 2"}] = Context.list_next_actions(url_resolver, user)
    end

    test "add creates a new next action on a content node", %{
      user: user,
      url_resolver: url_resolver
    } do
      content_node = Factories.insert!(:content_node)
      Context.create_next_action(user, SomeAction, content_node: content_node)
      assert [_] = Context.list_next_actions(url_resolver, user)
    end

    test "add the same action multiple times on the same content node increases it's count", %{
      user: user,
      url_resolver: url_resolver
    } do
      content_node = Factories.insert!(:content_node)
      other_node = Factories.insert!(:content_node)
      Context.create_next_action(user, SomeAction, content_node: content_node)
      Context.create_next_action(user, SomeAction, content_node: other_node)
      Context.create_next_action(user, SomeAction, content_node: content_node)

      assert [%{title: "Test: 2"}] = Context.list_next_actions(url_resolver, user, content_node)

      assert [%{title: "Test: 1"}] = Context.list_next_actions(url_resolver, user, other_node)
    end
  end

  describe "clear_next_action/3" do
    test "clearing a non existing action does nothing", %{user: user, url_resolver: _url_resolver} do
      Context.clear_next_action(user, :does_not_exist)

      Context.clear_next_action(user, :with_content_node, Factories.insert!(:content_node))
    end

    test "clearing an existing action removes it from the list", %{
      user: user,
      url_resolver: url_resolver
    } do
      Context.create_next_action(user, SomeAction)
      assert [_] = Context.list_next_actions(url_resolver, user)
      Context.clear_next_action(user, SomeAction)
      assert [] = Context.list_next_actions(url_resolver, user)
    end

    test "clearing an existing action with a content node removes it from the list", %{
      user: user,
      url_resolver: url_resolver
    } do
      content_node = Factories.insert!(:content_node)
      Context.create_next_action(user, SomeAction, content_node: content_node)
      assert [_] = Context.list_next_actions(url_resolver, user, content_node)
      Context.clear_next_action(user, SomeAction, content_node)
      assert [] = Context.list_next_actions(url_resolver, user, content_node)
    end
  end
end
