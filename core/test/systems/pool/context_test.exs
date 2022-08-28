defmodule Systems.Pool.ContextTest do
  use Core.DataCase
  alias Core.Factories

  alias Systems.Pool.Context

  setup do
    user = Factories.insert!(:member)
    pool = Factories.insert!(:pool, %{name: "test_pool"})

    {:ok, user: user, pool: pool}
  end

  describe "link/2" do
    test "link once succeeds", %{user: %{id: user_id} = user, pool: pool} do
      Context.link!(pool, user)

      assert %{
               participants: [
                 %{
                   id: ^user_id
                 }
               ]
             } = Context.get!(pool.id, [:participants])
    end

    test "link twice succeeds", %{user: %{id: user_id} = user, pool: pool} do
      # testing: on_conflict
      Context.link!(pool, user)
      Context.link!(pool, user)

      assert %{
               participants: [
                 %{
                   id: ^user_id
                 }
               ]
             } = Context.get!(pool.id, [:participants])
    end
  end

  describe "unlink/2" do
    test "unlink once succeeds", %{user: user, pool: pool} do
      Context.link!(pool, user)
      Context.unlink!(pool, user)

      assert %{
               participants: []
             } = Context.get!(pool.id, [:participants])
    end

    test "unlink twice succeeds", %{user: user, pool: pool} do
      Context.link!(pool, user)
      Context.unlink!(pool, user)
      Context.unlink!(pool, user)

      assert %{
               participants: []
             } = Context.get!(pool.id, [:participants])
    end
  end
end
