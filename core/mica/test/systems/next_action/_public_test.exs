defmodule Systems.NextAction.PublicTest do
  use Core.DataCase
  alias Core.Factories

  alias Systems.NextAction.Public

  defmodule SomeAction do
    @behaviour Systems.NextAction.ViewModel
    use CoreWeb, :verified_routes

    @impl Systems.NextAction.ViewModel
    def to_view_model(count, _params) do
      %{
        title: "Test: #{count}",
        description: "Testing",
        cta_label: "Open test",
        cta_action: %{type: :redirect, to: "http://example.org"}
      }
    end
  end

  setup do
    {:ok, user: Factories.insert!(:member)}
  end

  describe "list_next_actions/2" do
    test "show the users actions", %{user: user} do
      Public.create_next_action(user, SomeAction)
      assert [_] = Public.list_next_actions(user)
      other_user = Factories.insert!(:member)
      assert [] = Public.list_next_actions(other_user)
    end
  end

  describe "create_next_action/3" do
    test "add creates a new next action: without key", %{user: user} do
      Public.create_next_action(user, SomeAction)
      assert [_] = Public.list_next_actions(user)
    end

    test "add creates a new next action: with key", %{user: user} do
      Public.create_next_action(user, SomeAction, key: "1")
      assert [_] = Public.list_next_actions(user)
    end

    test "add the same action multiple times increases it's count: without key", %{
      user: user
    } do
      Public.create_next_action(user, SomeAction)
      Public.create_next_action(user, SomeAction)
      assert [%{title: "Test: 2"}] = Public.list_next_actions(user)
    end

    test "add the same action multiple times increases it's count: with key", %{
      user: user
    } do
      Public.create_next_action(user, SomeAction, key: "1")
      Public.create_next_action(user, SomeAction, key: "1")

      assert [%{title: "Test: 2"}] = Public.list_next_actions(user)
    end
  end

  describe "clear_next_action/3" do
    test "clearing a non existing action does nothing", %{user: user} do
      Public.clear_next_action(user, :does_not_exist)
    end

    test "clearing an existing action removes it from the list", %{
      user: user
    } do
      Public.create_next_action(user, SomeAction)
      assert [_] = Public.list_next_actions(user)
      Public.clear_next_action(user, SomeAction)
      assert [] = Public.list_next_actions(user)
    end

    test "clearing an existing action with a key removes it from the list", %{
      user: user
    } do
      Public.create_next_action(user, SomeAction, key: "1")
      assert [_] = Public.list_next_actions(user)
      Public.clear_next_action(user, SomeAction, key: "1")
      assert [] = Public.list_next_actions(user)
    end

    test "clearing an existing action without the key: no remove", %{
      user: user
    } do
      Public.create_next_action(user, SomeAction, key: "1")
      assert [_] = Public.list_next_actions(user)
      Public.clear_next_action(user, SomeAction)
      assert [_] = Public.list_next_actions(user)
    end
  end
end
