defmodule Systems.NextAction.PublicTest do
  use Core.DataCase
  alias Core.Factories

  alias Systems.NextAction
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

  defmodule TitledAction do
    @behaviour Systems.NextAction.ViewModel

    @impl Systems.NextAction.ViewModel
    def to_view_model(_count, %{"title" => title}) do
      %{
        title: title,
        description: "Testing",
        cta_label: "Open test",
        cta_action: %{type: :redirect, to: "http://example.org"}
      }
    end
  end

  setup do
    {:ok, user: Factories.insert!(:member)}
  end

  defp create_titled(user, title, opts \\ []) do
    Public.create_next_action(
      user,
      TitledAction,
      Keyword.merge([key: title, params: %{"title" => title}], opts)
    )
  end

  defp created_seconds_ago(user, key, seconds) do
    inserted_at =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(-seconds)
      |> NaiveDateTime.truncate(:second)

    from(na in NextAction.Model, where: na.user_id == ^user.id and na.key == ^key)
    |> Repo.update_all(set: [inserted_at: inserted_at])
  end

  defp stored_priority(user, key) do
    Repo.get_by!(NextAction.Model, user_id: user.id, key: key).priority
  end

  defp titles(view_models), do: Enum.map(view_models, & &1.title)

  describe "priority" do
    test "defaults to normal when no priority is given", %{user: user} do
      create_titled(user, "a")
      assert stored_priority(user, "a") == :normal
    end

    test "stores a high priority", %{user: user} do
      create_titled(user, "a", priority: :high)
      assert stored_priority(user, "a") == :high
    end

    test "stores a low priority", %{user: user} do
      create_titled(user, "a", priority: :low)
      assert stored_priority(user, "a") == :low
    end

    test "creating again with a priority changes it", %{user: user} do
      create_titled(user, "a", priority: :low)
      create_titled(user, "a", priority: :high)
      assert stored_priority(user, "a") == :high
      assert [%{title: "a"}] = Public.list_next_actions(user)
    end

    test "creating again without a priority keeps it", %{user: user} do
      create_titled(user, "a", priority: :high)
      create_titled(user, "a")
      assert stored_priority(user, "a") == :high
    end

    test "creating again without a key keeps the priority and increases the count", %{
      user: user
    } do
      Public.create_next_action(user, SomeAction, priority: :low)
      Public.create_next_action(user, SomeAction)
      assert [%{title: "Test: 2"}] = Public.list_next_actions(user)
      assert Repo.get_by!(NextAction.Model, user_id: user.id).priority == :low
    end

    test "rejects a nil priority", %{user: user} do
      assert_raise Ecto.InvalidChangesetError, fn ->
        create_titled(user, "a", priority: nil)
      end
    end

    test "rejects an unknown priority", %{user: user} do
      assert_raise Ecto.InvalidChangesetError, fn ->
        create_titled(user, "a", priority: :urgent)
      end
    end
  end

  describe "order" do
    setup %{user: user} do
      create_titled(user, "low-new", priority: :low)
      create_titled(user, "normal-old")
      create_titled(user, "normal-new", priority: :normal)
      create_titled(user, "high-old", priority: :high)

      created_seconds_ago(user, "low-new", 0)
      created_seconds_ago(user, "normal-old", 200)
      created_seconds_ago(user, "normal-new", 100)
      created_seconds_ago(user, "high-old", 300)

      :ok
    end

    test "list_next_actions/1 orders by priority, then newest first", %{user: user} do
      assert ["high-old", "normal-new", "normal-old", "low-new"] =
               titles(Public.list_next_actions(user))
    end

    test "list_next_actions/1 keeps higher priorities within its limit", %{user: user} do
      for n <- 1..10, do: create_titled(user, "normal-#{n}")

      list = titles(Public.list_next_actions(user))
      assert length(list) == 10
      assert List.first(list) == "high-old"
      refute "low-new" in list
    end

    test "next_best_action/1 returns the highest priority", %{user: user} do
      assert %{title: "high-old"} = Public.next_best_action(user)
    end

    test "next_best_action!/1 returns the highest priority", %{user: user} do
      assert %{title: "high-old"} = Public.next_best_action!(user)
    end

    test "list_next_actions_by_type/2 orders by priority, then newest first", %{user: user} do
      Public.create_next_action(user, SomeAction, priority: :high)

      assert ["high-old", "normal-new", "normal-old", "low-new"] =
               titles(Public.list_next_actions_by_type(user, TitledAction))
    end

    test "next_best_action_for_scope/3 returns the highest priority within the scope", %{
      user: user
    } do
      assert %{title: "normal-new"} =
               Public.next_best_action_for_scope(user, TitledAction, [
                 "low-new",
                 "normal-old",
                 "normal-new"
               ])
    end

    test "next_best_action_for_key/2 returns the highest priority for the key", %{user: user} do
      Public.create_next_action(user, SomeAction, key: "shared", priority: :low)
      create_titled(user, "shared", priority: :high)

      from(na in NextAction.Model,
        where: na.user_id == ^user.id and na.action == ^to_string(TitledAction)
      )
      |> Repo.update_all(set: [inserted_at: ~N[2020-01-01 00:00:00]])

      assert %{title: "shared"} = Public.next_best_action_for_key(user, "shared")
    end
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
