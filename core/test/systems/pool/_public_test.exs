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

  describe "panl_participant?/1" do
    test "returns true when user is participant of PANL pool" do
      user = Factories.insert!(:member)

      panl_pool =
        Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      Public.add_participant!(panl_pool, user)

      assert Public.panl_participant?(user)
    end

    test "returns false when user is not participant of PANL pool" do
      user = Factories.insert!(:member)
      Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      refute Public.panl_participant?(user)
    end

    test "returns false when PANL pool does not exist" do
      user = Factories.insert!(:member)

      if panl_pool = Public.get_panl() do
        Repo.delete(panl_pool)
      end

      refute Public.panl_participant?(user)
    end

    test "returns false when user is participant of different pool but not PANL pool" do
      user = Factories.insert!(:member)
      Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      other_pool = Factories.insert!(:pool, %{name: "Other Pool", director: :citizen})

      Public.add_participant!(other_pool, user)

      refute Public.panl_participant?(user)
    end

    test "returns true when user is participant of PANL pool and also other pools" do
      user = Factories.insert!(:member)

      panl_pool =
        Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      other_pool = Factories.insert!(:pool, %{name: "Other Pool", director: :citizen})

      Public.add_participant!(panl_pool, user)
      Public.add_participant!(other_pool, user)

      assert Public.panl_participant?(user)
    end
  end
end
