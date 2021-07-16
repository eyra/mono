defmodule Core.NextActionsTest do
  use Core.DataCase
  alias Core.Factories

  alias Core.NextActions

  setup do
    {:ok, user: Factories.insert!(:member)}
  end

  describe "list_next_actions/2" do
    test "show the users actions", %{user: user} do
      NextActions.create_next_action(user, :a_test_action)
      assert [_] = NextActions.list_next_actions(user)
      other_user = Factories.insert!(:member)
      assert [] = NextActions.list_next_actions(other_user)
    end

    test "can filter actions by content node", %{user: user} do
      content_node = Factories.insert!(:content_node)
      NextActions.create_next_action(user, :a_test_action, content_node: content_node)
      assert [_] = NextActions.list_next_actions(user, content_node)
      # Filter by another node shows no results
      assert [] = NextActions.list_next_actions(user, Factories.insert!(:content_node))
    end
  end

  describe "create_next_action/3" do
    test "add creates a new next action", %{user: user} do
      NextActions.create_next_action(user, :a_test_action)
      assert [_] = NextActions.list_next_actions(user)
    end

    test "add the same action multiple times increases it's count", %{user: user} do
      NextActions.create_next_action(user, :a_test_action)
      NextActions.create_next_action(user, :a_test_action)
      assert [%{count: 2}] = NextActions.list_next_actions(user)
    end

    test "add creates a new next action on a content node", %{user: user} do
      content_node = Factories.insert!(:content_node)
      NextActions.create_next_action(user, :a_test_action, content_node: content_node)
      assert [_] = NextActions.list_next_actions(user)
    end

    test "add the same action multiple times on the same content node increases it's count", %{
      user: user
    } do
      content_node = Factories.insert!(:content_node)
      other_node = Factories.insert!(:content_node)
      NextActions.create_next_action(user, :a_test_action, content_node: content_node)
      NextActions.create_next_action(user, :a_test_action, content_node: other_node)
      NextActions.create_next_action(user, :a_test_action, content_node: content_node)
      assert [%{count: 2}] = NextActions.list_next_actions(user, content_node)
      assert [%{count: 1}] = NextActions.list_next_actions(user, other_node)
    end
  end

  describe "clear_next_action/3" do
    test "clearing a non existing action does nothing", %{user: user} do
      NextActions.clear_next_action(user, :does_not_exist)

      NextActions.clear_next_action(user, :with_content_node, Factories.insert!(:content_node))
    end

    test "clearing an existing action removes it from the list", %{user: user} do
      NextActions.create_next_action(user, :test_action)
      assert [_] = NextActions.list_next_actions(user)
      NextActions.clear_next_action(user, :test_action)
      assert [] = NextActions.list_next_actions(user)
    end

    test "clearing an existing action with a content node removes it from the list", %{user: user} do
      content_node = Factories.insert!(:content_node)
      NextActions.create_next_action(user, :test_action, content_node: content_node)
      assert [_] = NextActions.list_next_actions(user, content_node)
      NextActions.clear_next_action(user, :test_action, content_node)
      assert [] = NextActions.list_next_actions(user, content_node)
    end
  end

  describe "to_view_model/2" do
  end
end
