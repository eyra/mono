defmodule Systems.Home.PageBuilderTest do
  use Core.DataCase

  alias Systems.Home
  alias Systems.Pool

  alias Core.Factories

  defp block_keys(vm), do: Enum.map(vm.blocks, &elem(&1, 0))

  defp give_reward(user, amount \\ 1500) do
    Factories.insert!(:reward, %{
      user: user,
      amount: amount,
      idempotence_key: "test=#{System.unique_integer([:positive])}"
    })
  end

  defp make_panl_participant(user) do
    panl_pool =
      Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

    Pool.Public.add_participant!(panl_pool, user)
  end

  describe "view_model/2 rewards_summary visibility" do
    test "non-panl member WITH rewards sees rewards_summary" do
      user = Factories.insert!(:member, %{creator: false})
      give_reward(user)

      refute Pool.Public.participant?(:panl, user)

      vm = Home.PageBuilder.view_model(nil, %{current_user: user})

      assert :rewards_summary in block_keys(vm)
    end

    test "non-panl member WITHOUT rewards does not see rewards_summary" do
      user = Factories.insert!(:member, %{creator: false})

      refute Pool.Public.participant?(:panl, user)

      vm = Home.PageBuilder.view_model(nil, %{current_user: user})

      refute :rewards_summary in block_keys(vm)
    end

    test "panl member WITH rewards still sees rewards_summary" do
      user = Factories.insert!(:member, %{creator: false})
      give_reward(user)
      make_panl_participant(user)

      assert Pool.Public.participant?(:panl, user)

      vm = Home.PageBuilder.view_model(nil, %{current_user: user})

      assert :rewards_summary in block_keys(vm)
    end

    test "panl member WITHOUT rewards does not see rewards_summary" do
      user = Factories.insert!(:member, %{creator: false})
      make_panl_participant(user)

      vm = Home.PageBuilder.view_model(nil, %{current_user: user})

      refute :rewards_summary in block_keys(vm)
    end

    test "creator WITH rewards does not see rewards_summary" do
      user = Factories.insert!(:member, %{creator: true})
      give_reward(user)

      vm = Home.PageBuilder.view_model(nil, %{current_user: user})

      refute :rewards_summary in block_keys(vm)
    end
  end
end
