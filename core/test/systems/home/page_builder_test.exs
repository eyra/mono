defmodule Systems.Home.PageBuilderTest do
  use Core.DataCase

  alias Systems.Home
  alias Systems.Pool
  alias Systems.Advert
  alias Systems.Assignment
  alias Systems.Fund

  alias Core.Factories

  defp block_keys(vm), do: Enum.map(vm.blocks, &elem(&1, 0))

  defp block_params(vm, name) do
    {^name, %{params: params}} = Enum.find(vm.blocks, fn {k, _} -> k == name end)
    params
  end

  # Build an online + funded + open advert placed inside the Panl pool so it
  # surfaces on the home page's Panl marketplace block. reward_value 0
  # short-circuits the funding check so we don't need to wire up a Fund +
  # currency. The factory's own `test_pool` is discarded — we swap the
  # submission's pool to Panl so the pool-scoped query sees it.
  defp create_open_online_advert(creator) do
    panl_pool =
      Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

    advert = Advert.Factories.create_advert(creator, :accepted, 1)
    {:ok, advert} = advert |> Ecto.Changeset.change(status: :online) |> Repo.update()

    {:ok, _} =
      advert.submission
      |> Ecto.Changeset.change(reward_value: 0, pool_id: panl_pool.id)
      |> Repo.update()

    advert
  end

  defp give_reward(user, amount \\ 1500) do
    Factories.insert!(:reward, %{
      user: user,
      fund: euro_fund(),
      amount: amount,
      idempotence_key: "test=#{System.unique_integer([:positive])}"
    })
  end

  # The rewards-summary card lists payable (euro) rewards only, so tests that
  # expect the card to appear must fund their rewards in euro.
  defp euro_fund do
    euro = Fund.Factories.create_currency("euro", :legal, "€", 2)
    Fund.Factories.create_fund("euro-fund-#{System.unique_integer([:positive])}", euro)
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

    test "creator WITH rewards sees rewards_summary (creators can participate too)" do
      user = Factories.insert!(:member, %{creator: true})
      give_reward(user)

      vm = Home.PageBuilder.view_model(nil, %{current_user: user})

      assert :rewards_summary in block_keys(vm)
    end

    test "payout handoff body interpolates the approved amount (no stray placeholder)" do
      user = Factories.insert!(:member, %{creator: false})

      Factories.insert!(:reward, %{
        user: user,
        fund: euro_fund(),
        amount: 2000,
        status: :approved,
        idempotence_key: "approved=#{System.unique_integer([:positive])}"
      })

      vm = Home.PageBuilder.view_model(nil, %{current_user: user})

      assert %{labels: %{payout_handoff_body: body}} = block_params(vm, :rewards_summary)
      refute body =~ "%{amount}"
      assert body =~ "20"
    end
  end

  describe "view_model/2 panl_marketplace (future studies) visibility" do
    test "non-panl member does not see panl_marketplace" do
      user = Factories.insert!(:member, %{creator: false})

      refute Pool.Public.participant?(:panl, user)

      vm = Home.PageBuilder.view_model(nil, %{current_user: user})

      refute :panl_marketplace in block_keys(vm)
    end

    test "panl member sees panl_marketplace" do
      user = Factories.insert!(:member, %{creator: false})
      make_panl_participant(user)

      vm = Home.PageBuilder.view_model(nil, %{current_user: user})

      assert :panl_marketplace in block_keys(vm)
    end
  end

  describe "view_model/2 panl_marketplace shape (home card limit / more link)" do
    setup do
      researcher = Factories.insert!(:creator)
      user = Factories.insert!(:member, %{creator: false})
      make_panl_participant(user)

      for _ <- 1..5, do: create_open_online_advert(researcher)

      {:ok, user: user}
    end

    test "caps displayed cards at the home page limit", %{user: user} do
      vm = Home.PageBuilder.view_model(nil, %{current_user: user})

      assert %{cards: cards} = block_params(vm, :panl_marketplace)
      assert length(cards) == 3
    end

    test "reports the total advert count, not the capped card count", %{user: user} do
      vm = Home.PageBuilder.view_model(nil, %{current_user: user})

      assert %{count: 5} = block_params(vm, :panl_marketplace)
    end

    test "links to the panl pool marketplace via more_path", %{user: user} do
      vm = Home.PageBuilder.view_model(nil, %{current_user: user})

      %Pool.Model{id: panl_id} = Pool.Public.get_panl()
      assert %{more_path: more_path} = block_params(vm, :panl_marketplace)
      assert more_path == "/pool/#{panl_id}/marketplace"
    end
  end

  describe "view_model/2 participated (activities) visibility" do
    test "non-panl member WITH a participated assignment sees participated" do
      user = Factories.insert!(:member, %{creator: false})
      assignment = Assignment.Factories.create_assignment(31, 1)
      Assignment.Public.add_participant!(assignment, user)

      refute Pool.Public.participant?(:panl, user)

      vm = Home.PageBuilder.view_model(nil, %{current_user: user})

      assert :participated in block_keys(vm)
    end

    test "member WITHOUT any participation does not see participated" do
      user = Factories.insert!(:member, %{creator: false})

      vm = Home.PageBuilder.view_model(nil, %{current_user: user})

      refute :participated in block_keys(vm)
    end
  end
end
