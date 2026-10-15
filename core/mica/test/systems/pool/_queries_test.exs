defmodule Systems.Pool.QueriesTest do
  use Core.DataCase, async: true

  import Systems.Pool.Queries
  alias Core.Repo
  alias Systems.Pool

  describe "pool_query/0" do
    test "no pools", _ do
      assert [] = Repo.all(pool_query())
    end

    test "2 pools", _ do
      Factories.insert!(:pool, %{name: "pool1", director: :citizen, currency: nil})
      Factories.insert!(:pool, %{name: "pool2", director: :citizen, currency: nil})
      assert [%Pool.Model{}, %Pool.Model{}] = Repo.all(pool_query())
    end
  end

  describe "pool_query/1" do
    test "no pools for currency", _ do
      currency = Factories.insert!(:currency)
      assert [] = Repo.all(pool_query(currency))
    end

    test "2 pools for currency", _ do
      currency = Factories.insert!(:currency)
      Factories.insert!(:pool, %{name: "pool1", director: :citizen, currency: currency})
      Factories.insert!(:pool, %{name: "pool2", director: :citizen, currency: currency})
      assert [%Pool.Model{}, %Pool.Model{}] = Repo.all(pool_query(currency))
    end
  end

  describe "pool_query/2" do
    test "no pools for user", _ do
      user = Factories.insert!(:member)
      assert [] = Repo.all(pool_query(user, :participant))
    end

    test "2 pools for user", _ do
      user = Factories.insert!(:member)
      pool_1 = Factories.insert!(:pool, %{name: "pool1", director: :citizen, currency: nil})
      pool_2 = Factories.insert!(:pool, %{name: "pool2", director: :citizen, currency: nil})
      Pool.Public.add_participant!(pool_1, user)
      Pool.Public.add_participant!(pool_2, user)
      assert [%Pool.Model{}, %Pool.Model{}] = Repo.all(pool_query(user, :participant))
    end
  end

  describe "pool_query/3" do
    test "no pools for currency + user", _ do
      user = Factories.insert!(:member)
      currency = Factories.insert!(:currency)
      assert [] = Repo.all(pool_query(currency, user, :participant))
    end

    test "2 pools for currency + user", _ do
      user = Factories.insert!(:member)
      currency_a = Factories.insert!(:currency)
      currency_b = Factories.insert!(:currency)

      pool_1 =
        Factories.insert!(:pool, %{name: "pool1", director: :citizen, currency: currency_a})

      pool_2 =
        Factories.insert!(:pool, %{name: "pool2", director: :citizen, currency: currency_a})

      pool_3 =
        Factories.insert!(:pool, %{name: "pool2", director: :citizen, currency: currency_b})

      Pool.Public.add_participant!(pool_1, user)
      Pool.Public.add_participant!(pool_2, user)
      Pool.Public.add_participant!(pool_3, user)

      assert [%Pool.Model{}, %Pool.Model{}] = Repo.all(pool_query(currency_a, user, :participant))
    end

    test "no pools for pool + user", _ do
      user = Factories.insert!(:member)
      pool = Factories.insert!(:pool, %{name: "pool", director: :citizen, currency: nil})
      assert [] = Repo.all(pool_query(pool, user, :participant))
    end

    test "1 pool for pool + user", _ do
      user = Factories.insert!(:member)
      pool = Factories.insert!(:pool, %{name: "pool", director: :citizen, currency: nil})
      Pool.Public.add_participant!(pool, user)
      assert [%Pool.Model{}] = Repo.all(pool_query(pool, user, :participant))
    end
  end
end
