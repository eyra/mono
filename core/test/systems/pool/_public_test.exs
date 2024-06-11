defmodule Systems.Pool.PublicTest do
  use Core.DataCase
  alias Core.Factories

  alias Systems.Pool.Public

  setup do
    user = Factories.insert!(:member)
    pool = Factories.insert!(:pool, %{name: "test_pool", director: :citizen})

    {:ok, user: user, pool: pool}
  end

  describe "add_participant/2" do
    test "add once succeeds", %{user: %{id: user_id} = user, pool: pool} do
      Public.add_participant!(pool, user)

      assert %{
               auth_node: %{
                 role_assignments: [
                   %{
                     role: :participant,
                     principal_id: ^user_id
                   }
                 ]
               }
             } = Public.get!(pool.id, auth_node: [:role_assignments])
    end

    test "add twice succeeds", %{user: %{id: user_id} = user, pool: pool} do
      Public.add_participant!(pool, user)
      Public.add_participant!(pool, user)

      assert %{
               auth_node: %{
                 role_assignments: [
                   %{
                     role: :participant,
                     principal_id: ^user_id
                   }
                 ]
               }
             } = Public.get!(pool.id, auth_node: [:role_assignments])
    end
  end

  describe "remove_participant/2" do
    test "remove once succeeds", %{user: user, pool: pool} do
      Public.add_participant!(pool, user)
      Public.remove_participant(pool, user)

      assert %{
               auth_node: %{
                 role_assignments: []
               }
             } = Public.get!(pool.id, auth_node: [:role_assignments])
    end

    test "remove twice succeeds", %{user: user, pool: pool} do
      Public.add_participant!(pool, user)
      Public.remove_participant(pool, user)
      Public.remove_participant(pool, user)

      assert %{
               auth_node: %{
                 role_assignments: []
               }
             } = Public.get!(pool.id, auth_node: [:role_assignments])
    end
  end
end
