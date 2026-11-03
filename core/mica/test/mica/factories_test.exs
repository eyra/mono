defmodule Mica.FactoriesTest do
  use Mica.DataCase, async: true

  alias Mica.Factories
  alias Mica.Repo

  describe "build(:authentication_entity)" do
    test "gives each entity a unique identifier, whatever the random state" do
      :rand.seed(:exsss, {1, 2, 3})
      first = Factories.build(:authentication_entity) |> Repo.insert!()

      :rand.seed(:exsss, {1, 2, 3})
      second = Factories.build(:authentication_entity) |> Repo.insert!()

      assert first.identifier != second.identifier
    end
  end
end
