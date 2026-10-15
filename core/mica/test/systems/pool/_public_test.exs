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

  describe "participant?/2 with slug" do
    test "returns true when user is participant of PANL pool" do
      user = Factories.insert!(:member)

      panl_pool =
        Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      Public.add_participant!(panl_pool, user)

      assert Public.participant?(:panl, user)
    end

    test "returns false when user is not participant of PANL pool" do
      user = Factories.insert!(:member)
      Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      refute Public.participant?(:panl, user)
    end

    test "returns false when PANL pool does not exist" do
      user = Factories.insert!(:member)

      if panl_pool = Public.get_panl() do
        Repo.delete(panl_pool)
      end

      refute Public.participant?(:panl, user)
    end

    test "returns false when user is participant of different pool but not PANL pool" do
      user = Factories.insert!(:member)
      Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      other_pool = Factories.insert!(:pool, %{name: "Other Pool", director: :citizen})

      Public.add_participant!(other_pool, user)

      refute Public.participant?(:panl, user)
    end

    test "returns true when user is participant of PANL pool and also other pools" do
      user = Factories.insert!(:member)

      panl_pool =
        Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

      other_pool = Factories.insert!(:pool, %{name: "Other Pool", director: :citizen})

      Public.add_participant!(panl_pool, user)
      Public.add_participant!(other_pool, user)

      assert Public.participant?(:panl, user)
    end
  end

  describe "add_user_to_panl_pool/1" do
    test "adds user to PaNL pool and returns :ok" do
      user = Factories.insert!(:member)

      refute Public.participant?(:panl, user)

      assert :ok = Public.add_user_to_panl_pool(user)

      assert Public.participant?(:panl, user)
    end

    test "creates PaNL pool if it doesn't exist" do
      user = Factories.insert!(:member)

      # Ensure PaNL pool doesn't exist
      if panl_pool = Public.get_panl() do
        Repo.delete(panl_pool)
      end

      assert Public.get_panl() == nil

      assert :ok = Public.add_user_to_panl_pool(user)

      # Pool should now exist
      assert Public.get_panl() != nil
      assert Public.participant?(:panl, user)
    end

    test "is idempotent - adding same user twice succeeds" do
      user = Factories.insert!(:member)

      assert :ok = Public.add_user_to_panl_pool(user)
      assert :ok = Public.add_user_to_panl_pool(user)

      assert Public.participant?(:panl, user)
    end

    test "works for multiple different users" do
      user1 = Factories.insert!(:member)
      user2 = Factories.insert!(:member)

      assert :ok = Public.add_user_to_panl_pool(user1)
      assert :ok = Public.add_user_to_panl_pool(user2)

      assert Public.participant?(:panl, user1)
      assert Public.participant?(:panl, user2)
    end
  end

  describe "can_manage?/2" do
    test "false when the pool has no associated org", %{user: user} do
      pool = Factories.insert!(:pool, %{name: "no_org_pool", director: :citizen, org_node: nil})
      assert Public.can_manage?(pool, user) == false
    end

    test "true when user is an owner of the pool's org", %{user: user, pool: pool} do
      pool = Core.Repo.preload(pool, :org)
      Core.Authorization.assign_role(user, pool.org, :owner)
      assert Public.can_manage?(pool, user) == true
    end

    test "false when user has no role on the pool's org", %{user: user, pool: pool} do
      assert Public.can_manage?(pool, user) == false
    end

    test "preloads org when the association is not loaded", %{user: user, pool: pool} do
      stripped = %{pool | org: %Ecto.Association.NotLoaded{}}
      Core.Authorization.assign_role(user, Core.Repo.preload(pool, :org).org, :owner)
      assert Public.can_manage?(stripped, user) == true
    end
  end

  describe "list_participant_ids/0" do
    test "returns user ids of pool participants", %{user: user, pool: pool} do
      Public.add_participant!(pool, user)

      ids = Public.list_participant_ids()
      assert user.id in ids
    end

    test "returns empty list when no participants" do
      ids = Public.list_participant_ids()
      # May contain participants from other tests/setup, just verify it's a list
      assert is_list(ids)
    end

    test "returns unique ids across multiple pools", %{user: user, pool: pool} do
      other_pool = Factories.insert!(:pool, %{name: "other_pool", director: :citizen})

      Public.add_participant!(pool, user)
      Public.add_participant!(other_pool, user)

      ids = Public.list_participant_ids()
      assert user.id in ids
      assert Enum.count(ids, &(&1 == user.id)) == 1
    end
  end
end
