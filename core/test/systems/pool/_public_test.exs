defmodule Systems.Pool.PublicTest do
  use Core.DataCase
  alias Core.Factories

  alias Systems.Pool.Public

  setup do
    user = Factories.insert!(:member)
    pool = Factories.insert!(:pool, %{name: "test_pool", director: :citizen})

    {:ok, user: user, pool: pool}
  end

  describe "link/2" do
    test "link once succeeds", %{user: %{id: user_id} = user, pool: pool} do
      Public.link!(pool, user)

      assert %{
               participants: [
                 %{
                   id: ^user_id
                 }
               ]
             } = Public.get!(pool.id, [:participants])
    end

    test "link twice succeeds", %{user: %{id: user_id} = user, pool: pool} do
      # testing: on_conflict
      Public.link!(pool, user)
      Public.link!(pool, user)

      assert %{
               participants: [
                 %{
                   id: ^user_id
                 }
               ]
             } = Public.get!(pool.id, [:participants])
    end
  end

  describe "unlink/2" do
    test "unlink once succeeds", %{user: user, pool: pool} do
      Public.link!(pool, user)
      Public.unlink!(pool, user)

      assert %{
               participants: []
             } = Public.get!(pool.id, [:participants])
    end

    test "unlink twice succeeds", %{user: user, pool: pool} do
      Public.link!(pool, user)
      Public.unlink!(pool, user)
      Public.unlink!(pool, user)

      assert %{
               participants: []
             } = Public.get!(pool.id, [:participants])
    end
  end

  describe "update_pool_participations/3" do
    test "add", %{user: %{id: user_id} = user} do
      Public.update_pool_participations(user, ["vu_sbe_rpr_year1_2021"], [])

      assert %{
               participants: [%{id: ^user_id}]
             } = Public.get_by_name("vu_sbe_rpr_year1_2021", [:participants])

      assert %{
               participants: []
             } = Public.get_by_name("vu_sbe_rpr_year2_2021", [:participants])
    end

    test "add 2 for 2 pools", %{user: %{id: user_id} = user} do
      Public.update_pool_participations(
        user,
        [
          "vu_sbe_rpr_year1_2021",
          "vu_sbe_rpr_year2_2021"
        ],
        []
      )

      assert %{
               participants: [%{id: ^user_id}]
             } = Public.get_by_name("vu_sbe_rpr_year1_2021", [:participants])

      assert %{
               participants: [%{id: ^user_id}]
             } = Public.get_by_name("vu_sbe_rpr_year2_2021", [:participants])
    end

    test "remove 1 for 1 pools", %{user: user} do
      Public.update_pool_participations(user, ["vu_sbe_rpr_year1_2021"], [])
      Public.update_pool_participations(user, [], ["vu_sbe_rpr_year1_2021"])

      assert %{
               participants: []
             } = Public.get_by_name("vu_sbe_rpr_year1_2021", [:participants])
    end

    test "remove 2 for 2 pools", %{user: user} do
      Public.update_pool_participations(
        user,
        ["vu_sbe_iba_year1_2021", "vu_sbe_bk_year2_2021"],
        []
      )

      Public.update_pool_participations(user, [], [
        "vu_sbe_rpr_year1_2021",
        "vu_sbe_rpr_year2_2021"
      ])

      assert %{
               participants: []
             } = Public.get_by_name("vu_sbe_rpr_year1_2021", [:participants])

      assert %{
               participants: []
             } = Public.get_by_name("vu_sbe_rpr_year2_2021", [:participants])
    end
  end
end
