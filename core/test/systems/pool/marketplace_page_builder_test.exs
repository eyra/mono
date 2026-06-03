defmodule Systems.Pool.MarketplacePageBuilderTest do
  use Core.DataCase

  alias Systems.Pool
  alias Systems.Advert
  alias Core.Factories

  # Builds an advert that passes Advert.Public.validate_open/2 for any pool
  # member and binds its submission to the given pool: online status, an open
  # spot, and reward_value 0 (which short-circuits the funding check, so we
  # don't need to wire up a Fund + currency).
  defp create_online_advert_in_pool(creator, pool, opts \\ []) do
    subject_count = Keyword.get(opts, :subject_count, 1)
    submitted_at = Keyword.get(opts, :submitted_at)

    advert = Advert.Factories.create_advert(creator, :accepted, subject_count)

    {:ok, advert} =
      advert |> Ecto.Changeset.change(status: :online) |> Repo.update()

    {:ok, _submission} =
      advert.submission
      |> Ecto.Changeset.change(%{
        reward_value: 0,
        submitted_at: submitted_at,
        pool_id: pool.id
      })
      |> Repo.update()

    advert
  end

  defp creator, do: Factories.insert!(:creator)
  defp test_pool, do: Factories.insert!(:pool, %{name: "test_pool", director: :citizen})

  defp pool_member(pool) do
    user = Factories.insert!(:member, %{creator: false})
    Pool.Public.add_participant!(pool, user)
    user
  end

  defp build_assigns(user, pool),
    do: %{current_user: user, uri_path: "/pool/#{pool.id}/marketplace"}

  describe "view_model/2" do
    test "returns Overview > Marketplace breadcrumbs" do
      pool = test_pool()
      user = pool_member(pool)
      vm = Pool.MarketplacePageBuilder.view_model(pool, build_assigns(user, pool))

      assert [
               %{label: "Overview", path: "/"},
               %{label: "Marketplace", path: path}
             ] = vm.breadcrumbs

      assert path == "/pool/#{pool.id}/marketplace"
    end

    test "uses the landing_page hero titled Marketplace" do
      pool = test_pool()
      user = pool_member(pool)
      vm = Pool.MarketplacePageBuilder.view_model(pool, build_assigns(user, pool))

      assert %{type: :landing_page, params: %{title: "Marketplace"}} = vm.hero
    end

    test "exposes the pool in the view model" do
      pool = test_pool()
      user = pool_member(pool)
      vm = Pool.MarketplacePageBuilder.view_model(pool, build_assigns(user, pool))

      assert vm.pool.id == pool.id
    end

    test "pool member without available adverts sees empty items and years" do
      pool = test_pool()
      user = pool_member(pool)

      vm = Pool.MarketplacePageBuilder.view_model(pool, build_assigns(user, pool))

      assert vm.items == []
      assert vm.years == []
    end

    test "pool member sees eligible online adverts as items" do
      pool = test_pool()
      user = pool_member(pool)
      create_online_advert_in_pool(creator(), pool)

      vm = Pool.MarketplacePageBuilder.view_model(pool, build_assigns(user, pool))

      assert [%{card: %{type: :primary}}] = vm.items
    end

    test "items expose the published year, sourced from submission.submitted_at" do
      pool = test_pool()
      user = pool_member(pool)
      create_online_advert_in_pool(creator(), pool, submitted_at: ~N[2024-06-15 12:00:00])
      create_online_advert_in_pool(creator(), pool, submitted_at: ~N[2025-03-01 09:00:00])

      vm = Pool.MarketplacePageBuilder.view_model(pool, build_assigns(user, pool))

      assert Enum.map(vm.items, & &1.year) |> Enum.sort() == [2024, 2025]
    end

    test "years are deduplicated when multiple adverts share a year" do
      pool = test_pool()
      user = pool_member(pool)
      create_online_advert_in_pool(creator(), pool, submitted_at: ~N[2024-06-15 12:00:00])
      create_online_advert_in_pool(creator(), pool, submitted_at: ~N[2024-09-01 12:00:00])

      vm = Pool.MarketplacePageBuilder.view_model(pool, build_assigns(user, pool))

      assert vm.years == [2024]
    end

    test "years are sorted in descending order" do
      pool = test_pool()
      user = pool_member(pool)
      create_online_advert_in_pool(creator(), pool, submitted_at: ~N[2024-06-15 12:00:00])
      create_online_advert_in_pool(creator(), pool, submitted_at: ~N[2025-03-01 09:00:00])

      vm = Pool.MarketplacePageBuilder.view_model(pool, build_assigns(user, pool))

      assert vm.years == [2025, 2024]
    end

    test "adverts from other pools are excluded" do
      pool = test_pool()
      other_pool = Factories.insert!(:pool, %{name: "other_pool", director: :citizen})
      user = pool_member(pool)
      create_online_advert_in_pool(creator(), other_pool)

      vm = Pool.MarketplacePageBuilder.view_model(pool, build_assigns(user, pool))

      assert vm.items == []
    end

    test "adverts that fail validate_open (no open spots) are excluded" do
      pool = test_pool()
      user = pool_member(pool)
      create_online_advert_in_pool(creator(), pool, subject_count: 0)

      vm = Pool.MarketplacePageBuilder.view_model(pool, build_assigns(user, pool))

      assert vm.items == []
      assert vm.years == []
    end
  end
end
