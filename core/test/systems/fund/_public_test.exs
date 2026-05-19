defmodule Systems.Fund.PublicTest do
  use Core.DataCase

  alias Systems.{
    Fund,
    Bookkeeping
  }

  alias Core.Factories

  setup do
    currency = Fund.Factories.create_currency("fake_currency", :legal, "ƒ", 2)
    fund = Fund.Factories.create_fund("test", currency)
    {:ok, currency: currency, fund: fund}
  end

  test "create_reward/4", %{fund: %{available: fund_account, pending: reserve} = fund} do
    amount = 3500
    %{id: participant_id} = participant = Factories.insert!(:member, %{creator: false})
    reward_idempotence_key = "user:#{participant.id},fund:#{fund.id},assignment:1"
    deposit_idempotence_key = "#{reward_idempotence_key},type=deposit,attempt=0"

    {:ok, %{reward: %{id: reward_id}}} =
      Fund.Public.create_reward(fund, amount, participant, reward_idempotence_key)

    reward =
      Fund.Public.get_reward!(reward_id, [
        [:deposit, :payment, :user, fund: [:available, :pending]]
      ])

    journal_message = "Reserved ƒ35.00 on fund #{fund.name} ##{fund.id}"

    fund_balance_credit = fund_account.balance_credit
    fund_balance_debit = fund_account.balance_debit + amount

    reserve_balance_credit = reserve.balance_credit + amount
    reserve_balance_debit = reserve.balance_debit

    assert %{
             amount: ^amount,
             status: :reserved,
             user: %{
               id: ^participant_id
             },
             fund: %{
               available: %{
                 balance_credit: ^fund_balance_credit,
                 balance_debit: ^fund_balance_debit
               },
               pending: %{
                 balance_credit: ^reserve_balance_credit,
                 balance_debit: ^reserve_balance_debit
               }
             },
             deposit: %{
               idempotence_key: ^deposit_idempotence_key,
               journal_message: ^journal_message
             },
             payment: nil
           } = reward
  end

  test "rollback_deposit/4 fails without deposit", %{fund: fund} do
    participant = Factories.insert!(:member, %{creator: false})

    reward =
      Factories.insert!(:reward, %{
        idempotence_key: "1",
        amount: 3500,
        attempt: 0,
        user: participant,
        fund: fund
      })

    assert Fund.Public.rollback_deposit(reward) ==
             {:error, :revert_deposit, :deposit_not_available, %{}}
  end

  test "rollback_deposit/4 succeeds with deposit and without payment", %{
    fund: %{id: fund_id, available: fund_account, pending: reserve} = fund
  } do
    amount = 3500

    idempotence_key = "idempotence_key_1"

    participant = Factories.insert!(:member, %{creator: false})

    deposit =
      Factories.insert!(:book_entry, %{
        idempotence_key: idempotence_key,
        journal_message: "test_rollback_deposit"
      })

    Factories.insert!(:book_line, %{
      account: fund_account,
      entry: deposit,
      debit: amount,
      credit: 0
    })

    Factories.insert!(:book_line, %{account: reserve, entry: deposit, debit: 0, credit: amount})

    deposit = Bookkeeping.Public.get_entry(idempotence_key, lines: [:account])

    reward =
      Factories.insert!(:reward, %{
        idempotence_key: "1",
        amount: amount,
        attempt: 0,
        user: participant,
        fund: fund,
        deposit: deposit
      })

    assert {:ok,
            %{
              revert_deposit: %{
                validate: true,
                entry: %{
                  idempotence_key: "[REVERT] idempotence_key_1" = reverted_idempotence_key,
                  journal_message: "[REVERT] test_rollback_deposit"
                }
              }
            }} = Fund.Public.rollback_deposit(reward)

    reverted_deposit = Bookkeeping.Public.get_entry(reverted_idempotence_key, lines: [:account])

    fund_balance_credit = fund_account.balance_credit + amount
    fund_balance_debit = fund_account.balance_debit

    reserve_balance_credit = reserve.balance_credit
    reserve_balance_debit = reserve.balance_debit + amount

    assert %{
             lines: [
               %{
                 account: %{
                   balance_credit: ^fund_balance_credit,
                   balance_debit: ^fund_balance_debit,
                   identifier: ["fund", "test"]
                 },
                 credit: ^amount,
                 debit: 0
               },
               %{
                 account: %{
                   balance_credit: ^reserve_balance_credit,
                   balance_debit: ^reserve_balance_debit,
                   identifier: ["reserve", "test"]
                 },
                 credit: 0,
                 debit: ^amount
               }
             ]
           } = reverted_deposit

    assert %{
             available: %{
               balance_credit: ^fund_balance_credit,
               balance_debit: ^fund_balance_debit
             },
             pending: %{
               balance_credit: ^reserve_balance_credit,
               balance_debit: ^reserve_balance_debit
             }
           } = Fund.Public.get!(fund_id)
  end

  test "rollback_deposit/4 fails with deposit and payment", %{
    fund: %{available: fund_account, pending: reserve} = fund
  } do
    amount = 3500
    deposit_idempotence_key = "idempotence_key_deposit"
    payment_idempotence_key = "idempotence_key_payment"

    participant = Factories.insert!(:member, %{creator: false})

    deposit =
      Bookkeeping.Factories.create_entry(
        fund_account,
        reserve,
        amount,
        deposit_idempotence_key,
        "test_rollback_deposit"
      )

    payment =
      Bookkeeping.Factories.create_entry(
        fund_account,
        reserve,
        amount,
        payment_idempotence_key,
        "test_rollback_deposit"
      )

    reward =
      Factories.insert!(:reward, %{
        idempotence_key: "1",
        amount: amount,
        attempt: 0,
        user: participant,
        fund: fund,
        deposit: deposit,
        payment: payment
      })

    assert Fund.Public.rollback_deposit(reward) ==
             {:error, :revert_deposit, :payment_already_available, %{}}
  end

  test "payout_reward/4 succeeds with deposit available", %{
    fund: %{id: fund_id, available: fund_account, pending: reserve} = fund
  } do
    amount = 3500
    reward_idempotence_key = "1"
    deposit_idempotence_key = "idempotence_key_deposit"

    deposit =
      Bookkeeping.Factories.create_entry(
        fund_account,
        reserve,
        amount,
        deposit_idempotence_key,
        "test_payout_reward"
      )

    %{id: participant_id} = participant = Factories.insert!(:member, %{creator: false})

    reward =
      Factories.insert!(:reward, %{
        idempotence_key: reward_idempotence_key,
        amount: amount,
        attempt: 0,
        user: participant,
        fund: fund,
        deposit: deposit
      })

    payment_idempotence_key = Fund.RewardModel.payment_idempotence_key(reward)
    assert {:ok, _} = Fund.Public.payout_reward(reward_idempotence_key)

    fund_balance_credit = fund_account.balance_credit
    fund_balance_debit = fund_account.balance_debit

    reserve_balance_credit = reserve.balance_credit
    reserve_balance_debit = reserve.balance_debit + amount

    wallet_id = ["wallet", "fake_currency", "#{participant_id}"]

    assert %{
             lines: [
               %{
                 account: %{
                   balance_credit: ^reserve_balance_credit,
                   balance_debit: ^reserve_balance_debit,
                   identifier: ["reserve", "test"]
                 },
                 credit: nil,
                 debit: ^amount
               },
               %{
                 account: %{
                   balance_credit: ^amount,
                   balance_debit: 0,
                   identifier: ^wallet_id
                 },
                 credit: ^amount,
                 debit: nil
               }
             ]
           } = Bookkeeping.Public.get_entry(payment_idempotence_key, lines: [:account])

    assert %{
             available: %{
               balance_credit: ^fund_balance_credit,
               balance_debit: ^fund_balance_debit
             },
             pending: %{
               balance_credit: ^reserve_balance_credit,
               balance_debit: ^reserve_balance_debit
             }
           } = Fund.Public.get!(fund_id)
  end

  test "payout_reward/4 succeeds without deposit", %{
    fund: fund
  } do
    amount = 3500

    participant = Factories.insert!(:member, %{creator: false})

    reward_idempotence_key = "1"
    payment_idempotence_key = Fund.RewardModel.payment_idempotence_key(reward_idempotence_key)

    Factories.insert!(:reward, %{
      idempotence_key: reward_idempotence_key,
      amount: amount,
      attempt: 0,
      user: participant,
      fund: fund
    })

    journal_message = "Payout ƒ35.00 on fund #{fund.name} ##{fund.id}"

    assert {:ok,
            %{
              reward: %{
                deposit: nil,
                payment: %{
                  idempotence_key: ^payment_idempotence_key,
                  journal_message: ^journal_message
                }
              }
            }} = Fund.Public.payout_reward(reward_idempotence_key)
  end

  test "payout_reward/4 fails with payment available", %{
    fund: %{currency: currency, available: fund_account, pending: reserve} = fund
  } do
    amount = 3500
    reward_idempotence_key = "1"
    deposit_idempotence_key = "1,type=deposit,attempt=0"
    payment_idempotence_key = "1,type=payment"

    participant = Factories.insert!(:member, %{creator: false})
    wallet = Fund.Factories.create_wallet(participant, currency)

    deposit =
      Bookkeeping.Factories.create_entry(
        fund_account,
        reserve,
        amount,
        deposit_idempotence_key,
        "test_payout_reward"
      )

    payment =
      Bookkeeping.Factories.create_entry(
        reserve,
        wallet,
        amount,
        payment_idempotence_key,
        "test_payout_reward"
      )

    Factories.insert!(:reward, %{
      idempotence_key: reward_idempotence_key,
      amount: amount,
      attempt: 0,
      user: participant,
      fund: fund,
      deposit: deposit,
      payment: payment
    })

    assert {:error, _, :payment_already_available, _} =
             Fund.Public.payout_reward(reward_idempotence_key)
  end

  test "move_wallet_balance/4 succeeded" do
    a_b_c_2021 =
      Core.Factories.insert!(:book_account, %{
        identifier: ["wallet", "a_b_c_2021", "1"],
        balance_credit: 10_000,
        balance_debit: 5000
      })

    a_b_c_2022 =
      Core.Factories.insert!(:book_account, %{
        identifier: ["wallet", "a_b_c_2022", "1"],
        balance_credit: 0,
        balance_debit: 0
      })

    Fund.Public.move_wallet_balance(
      a_b_c_2021.identifier,
      a_b_c_2022.identifier,
      "idempotency_key",
      5001
    )

    assert %{
             balance_credit: 10_000,
             balance_debit: 10_000
           } = Bookkeeping.Public.get_account!(["wallet", "a_b_c_2021", "1"])

    assert %{
             balance_credit: 5000,
             balance_debit: 0
           } = Bookkeeping.Public.get_account!(["wallet", "a_b_c_2022", "1"])
  end

  test "move_wallet_balance/4 skipped: exceeding limit" do
    a_b_c_2021 =
      Core.Factories.insert!(:book_account, %{
        identifier: ["wallet", "a_b_c_2021", "1"],
        balance_credit: 10_000,
        balance_debit: 5000
      })

    a_b_c_2022 =
      Core.Factories.insert!(:book_account, %{
        identifier: ["wallet", "a_b_c_2022", "1"],
        balance_credit: 0,
        balance_debit: 0
      })

    Fund.Public.move_wallet_balance(
      a_b_c_2021.identifier,
      a_b_c_2022.identifier,
      "idempotency_key",
      5000
    )

    assert %{
             balance_credit: 10_000,
             balance_debit: 5000
           } = Bookkeeping.Public.get_account!(["wallet", "a_b_c_2021", "1"])

    assert %{
             balance_credit: 0,
             balance_debit: 0
           } = Bookkeeping.Public.get_account!(["wallet", "a_b_c_2022", "1"])
  end

  test "move_wallet_balance/4 skipped: from account does not exist" do
    a_b_c_2022 =
      Core.Factories.insert!(:book_account, %{
        identifier: ["wallet", "a_b_c_2022", "1"],
        balance_credit: 0,
        balance_debit: 0
      })

    assert_raise RuntimeError, fn ->
      Fund.Public.move_wallet_balance(
        ["wallet", "a_b_c_2021", "1"],
        a_b_c_2022.identifier,
        "idempotency_key",
        5000
      )
    end
  end

  test "multiply_rewards/2 succeeds", %{
    fund: %{available: fund_account, pending: reserve} = fund
  } do
    amount = 250
    multiplier = 10
    expected_mount = amount * (multiplier - 1)

    reserve_debit = 0
    expected_reserve_debit = reserve_debit + 2 * expected_mount

    fund_debit = 5500
    expected_fund_debit = fund_debit + 2 * expected_mount

    expected_wallet_credit = amount * multiplier

    participant1 = Factories.insert!(:member, %{creator: false})
    participant2 = Factories.insert!(:member, %{creator: false})

    Factories.insert!(:reward, %{
      idempotence_key: "participant=1",
      amount: amount,
      attempt: 0,
      user: participant1,
      fund: fund
    })

    Factories.insert!(:reward, %{
      idempotence_key: "participant=2",
      amount: amount,
      attempt: 0,
      user: participant2,
      fund: fund
    })

    Fund.Public.payout_reward("participant=1")
    Fund.Public.payout_reward("participant=2")

    assert %{debit: ^reserve_debit} = Bookkeeping.Public.balance(reserve)
    assert %{debit: ^fund_debit} = Bookkeeping.Public.balance(fund_account)

    assert [
             %{balance_credit: ^amount},
             %{balance_credit: ^amount}
           ] = Fund.Public.list_wallets(fund)

    assert [
             ok: %{
               reward: %{
                 amount: ^expected_mount
               }
             },
             ok: %{
               reward: %{
                 amount: ^expected_mount
               }
             }
           ] = Fund.Public.multiply_rewards(fund, 10)

    assert %{debit: ^expected_reserve_debit} = Bookkeeping.Public.balance(reserve)
    assert %{debit: ^expected_fund_debit} = Bookkeeping.Public.balance(fund_account)

    assert [
             %{balance_credit: ^expected_wallet_credit},
             %{balance_credit: ^expected_wallet_credit}
           ] = Fund.Public.list_wallets(fund)
  end

  describe "mark_pending_approval/1" do
    setup %{fund: fund} do
      participant = Factories.insert!(:member, %{creator: false})
      key = "user:#{participant.id},fund:#{fund.id},mark"
      {:ok, _} = Fund.Public.create_reward(fund, 1000, participant, key)
      {:ok, key: key}
    end

    test "transitions :reserved → :pending_approval", %{key: key} do
      assert {:ok, %{status: :pending_approval}} = Fund.Public.mark_pending_approval(key)
    end

    test "is idempotent on :pending_approval", %{key: key} do
      {:ok, _} = Fund.Public.mark_pending_approval(key)
      assert {:ok, %{status: :pending_approval}} = Fund.Public.mark_pending_approval(key)
    end

    test "is a no-op on :approved", %{key: key} do
      {:ok, _} = Fund.Public.approve_reward(key)
      assert {:ok, %{status: :approved}} = Fund.Public.mark_pending_approval(key)
    end

    test "returns error when reward not found" do
      assert {:error, :reward_not_found} = Fund.Public.mark_pending_approval("nope")
    end
  end

  describe "approve_reward/1" do
    setup %{fund: fund} do
      participant = Factories.insert!(:member, %{creator: false})
      key = "user:#{participant.id},fund:#{fund.id},approve"
      {:ok, _} = Fund.Public.create_reward(fund, 1000, participant, key)
      {:ok, key: key, participant: participant, fund: fund}
    end

    test "transitions :reserved → :approved and creates wallet payment", %{key: key} do
      assert {:ok, %{reward: %{status: :approved}, payment: %{payment_id: payment_id}}} =
               Fund.Public.approve_reward(key)

      refute is_nil(payment_id)
    end

    test "transitions :pending_approval → :approved", %{key: key} do
      {:ok, _} = Fund.Public.mark_pending_approval(key)
      assert {:ok, %{reward: %{status: :approved}}} = Fund.Public.approve_reward(key)
    end

    test "is idempotent on :approved", %{key: key} do
      {:ok, _} = Fund.Public.approve_reward(key)
      assert {:ok, %{status: :approved}} = Fund.Public.approve_reward(key)
    end

    test "overrides a :rejected reward (pay out anyway)", %{key: key} do
      {:ok, _} = Fund.Public.reject_reward(key)
      assert {:ok, _} = Fund.Public.approve_reward(key)
      assert %{status: :approved} = Fund.Public.get_reward(key, [])
    end

    test "returns error when reward not found" do
      assert {:error, :reward_not_found} = Fund.Public.approve_reward("nope")
    end
  end

  describe "reject_reward/1" do
    setup %{fund: %{available: fund_account, pending: reserve} = fund} do
      participant = Factories.insert!(:member, %{creator: false})
      key = "user:#{participant.id},fund:#{fund.id},reject"
      {:ok, _} = Fund.Public.create_reward(fund, 1000, participant, key)
      {:ok, key: key, fund: fund, fund_account: fund_account, reserve: reserve}
    end

    test "transitions :reserved → :rejected and reverts deposit", %{
      key: key,
      fund: %{id: fund_id, available: %{} = fund_account, pending: %{} = reserve}
    } do
      original_available = Bookkeeping.AccountModel.balance(fund_account)
      original_reserve = Bookkeeping.AccountModel.balance(reserve)

      assert {:ok, _} = Fund.Public.reject_reward(key)

      reloaded = Fund.Public.get!(fund_id)

      assert Bookkeeping.AccountModel.balance(reloaded.available) == original_available
      assert Bookkeeping.AccountModel.balance(reloaded.pending) == original_reserve
      assert %{status: :rejected, deposit_id: nil} = Fund.Public.get_reward(key, [])
    end

    test "transitions :pending_approval → :rejected", %{key: key} do
      {:ok, _} = Fund.Public.mark_pending_approval(key)
      assert {:ok, _} = Fund.Public.reject_reward(key)
      assert %{status: :rejected} = Fund.Public.get_reward(key, [])
    end

    test "is idempotent on :rejected", %{key: key} do
      {:ok, _} = Fund.Public.reject_reward(key)
      assert {:ok, %{status: :rejected}} = Fund.Public.reject_reward(key)
    end

    test "errors on :approved", %{key: key} do
      {:ok, _} = Fund.Public.approve_reward(key)
      assert {:error, :reward_already_approved} = Fund.Public.reject_reward(key)
    end

    test "returns error when reward not found" do
      assert {:error, :reward_not_found} = Fund.Public.reject_reward("nope")
    end
  end

  describe "list_pending_approvals/1" do
    setup %{fund: fund} do
      [u1, u2, u3] =
        for _ <- 1..3, do: Factories.insert!(:member, %{creator: false})

      {:ok, _} = Fund.Public.create_reward(fund, 1000, u1, "k1")
      {:ok, _} = Fund.Public.create_reward(fund, 2000, u2, "k2")
      {:ok, _} = Fund.Public.create_reward(fund, 3000, u3, "k3")

      {:ok, _} = Fund.Public.mark_pending_approval("k1")
      {:ok, _} = Fund.Public.approve_reward("k2")

      {:ok, fund: fund, u1: u1}
    end

    test "returns only :pending_approval rewards for the fund", %{fund: fund, u1: %{id: u1_id}} do
      assert [
               %{
                 idempotence_key: "k1",
                 amount: 1000,
                 status: :pending_approval,
                 user: %{id: ^u1_id}
               }
             ] =
               Fund.Public.list_pending_approvals(fund)
    end

    test "returns empty list for unrelated fund", %{} do
      currency = Fund.Factories.create_currency("isolated", :legal, "Ω", 2)
      other_fund = Fund.Factories.create_fund("other", currency)
      assert [] = Fund.Public.list_pending_approvals(other_fund)
    end
  end

  describe "reject_reward/2 reason + override" do
    setup %{fund: fund} do
      participant = Factories.insert!(:member, %{creator: false})
      key = "user:#{participant.id},fund:#{fund.id},override"
      {:ok, _} = Fund.Public.create_reward(fund, 1000, participant, key)
      {:ok, _} = Fund.Public.mark_pending_approval(key)

      {:ok, fund: fund, key: key}
    end

    test "stores rejection_reason and rejected_at when reason given", %{key: key} do
      assert {:ok, _} = Fund.Public.reject_reward(key, "No valid answers given")

      reward = Fund.Public.get_reward(key, [])
      assert reward.status == :rejected
      assert reward.rejection_reason == "No valid answers given"
      refute is_nil(reward.rejected_at)
    end

    test "leaves rejection_reason nil when no reason given", %{key: key} do
      assert {:ok, _} = Fund.Public.reject_reward(key)

      reward = Fund.Public.get_reward(key, [])
      assert reward.status == :rejected
      assert is_nil(reward.rejection_reason)
    end

    test "approve_reward overrides a rejected reward, paying from fund.available",
         %{key: key, fund: %{id: fund_id}} do
      {:ok, _} = Fund.Public.reject_reward(key, "initial decline")
      assert %{status: :rejected} = Fund.Public.get_reward(key, [])

      assert {:ok, _} = Fund.Public.approve_reward(key)

      reward = Fund.Public.get_reward(key, [])
      assert reward.status == :approved
      assert is_nil(reward.rejection_reason)
      assert is_nil(reward.rejected_at)
      refute is_nil(reward.payment_id)

      _ = fund_id
    end

    test "approve_reward of a rejected reward errors when fund.available is insufficient",
         %{key: key, fund: %{id: fund_id}} do
      {:ok, _} = Fund.Public.reject_reward(key, "decline")

      drain_amount = Fund.Model.amount_available(Fund.Public.get!(fund_id))

      Fund.Public.get!(fund_id).available
      |> Ecto.Changeset.change(%{balance_debit: drain_amount + 100_000})
      |> Core.Repo.update!()

      assert {:error, :insufficient_fund} = Fund.Public.approve_reward(key)
    end
  end

  describe "summarize_rewards/1" do
    test "returns all zeros when the user has no rewards" do
      user = Factories.insert!(:member, %{creator: false})

      assert %{pending_cents: 0, approved_cents: 0, rejected_cents: 0} =
               Fund.Public.summarize_rewards(user)
    end

    test "sums :reserved and :pending_approval into pending_cents", %{fund: fund} do
      user = Factories.insert!(:member, %{creator: false})

      Factories.insert!(:reward, %{
        user: user,
        fund: fund,
        amount: 100,
        status: :reserved,
        idempotence_key: "sr-reserved-100-#{System.unique_integer([:positive])}"
      })

      Factories.insert!(:reward, %{
        user: user,
        fund: fund,
        amount: 250,
        status: :pending_approval,
        idempotence_key: "sr-pending-250-#{System.unique_integer([:positive])}"
      })

      assert %{pending_cents: 350, approved_cents: 0, rejected_cents: 0} =
               Fund.Public.summarize_rewards(user)
    end

    test "folds :paid and :approved into approved_cents", %{fund: fund} do
      user = Factories.insert!(:member, %{creator: false})

      Factories.insert!(:reward, %{
        user: user,
        fund: fund,
        amount: 100,
        status: :approved,
        idempotence_key: "sr-approved-100-#{System.unique_integer([:positive])}"
      })

      Factories.insert!(:reward, %{
        user: user,
        fund: fund,
        amount: 400,
        status: :paid,
        idempotence_key: "sr-paid-400-#{System.unique_integer([:positive])}"
      })

      assert %{pending_cents: 0, approved_cents: 500, rejected_cents: 0} =
               Fund.Public.summarize_rewards(user)
    end

    test "sums :rejected into rejected_cents", %{fund: fund} do
      user = Factories.insert!(:member, %{creator: false})

      Factories.insert!(:reward, %{
        user: user,
        fund: fund,
        amount: 75,
        status: :rejected,
        idempotence_key: "sr-rejected-75-#{System.unique_integer([:positive])}"
      })

      assert %{pending_cents: 0, approved_cents: 0, rejected_cents: 75} =
               Fund.Public.summarize_rewards(user)
    end
  end

  describe "reject_reward/2 (multi)" do
    test "composes inside an existing Multi transaction", %{fund: fund} do
      participant = Factories.insert!(:member, %{creator: false})
      key = "user:#{participant.id},fund:#{fund.id},multi-reject"
      {:ok, _} = Fund.Public.create_reward(fund, 1500, participant, key)

      result =
        Ecto.Multi.new()
        |> Ecto.Multi.run(:noop, fn _, _ -> {:ok, :pre} end)
        |> Fund.Public.reject_reward(key)
        |> Core.Repo.commit()

      assert {:ok, %{noop: :pre, reject_status: %{status: :rejected}}} = result
      assert %{status: :rejected, deposit_id: nil} = Fund.Public.get_reward(key, [])
    end

    test "raises when reward not found" do
      assert_raise Fund.Public.FundError, fn ->
        Ecto.Multi.new()
        |> Fund.Public.reject_reward("nonexistent-key")
        |> Core.Repo.commit()
      end
    end

    test "fails the transaction with :reward_already_approved on an approved reward", %{
      fund: fund
    } do
      participant = Factories.insert!(:member, %{creator: false})
      key = "user:#{participant.id},fund:#{fund.id},multi-reject-approved"
      {:ok, _} = Fund.Public.create_reward(fund, 1500, participant, key)
      {:ok, _} = Fund.Public.mark_pending_approval(key)
      {:ok, _} = Fund.Public.approve_reward(key)

      result =
        Ecto.Multi.new()
        |> Ecto.Multi.run(:noop, fn _, _ -> {:ok, :pre} end)
        |> Fund.Public.reject_reward(key)
        |> Core.Repo.commit()

      assert {:error, :reject_guard, :reward_already_approved, _} = result
      assert %{status: :approved} = Fund.Public.get_reward(key, [])
    end

    test "is a pass-through no-op on an already-rejected reward", %{fund: fund} do
      participant = Factories.insert!(:member, %{creator: false})
      key = "user:#{participant.id},fund:#{fund.id},multi-reject-rejected"
      {:ok, _} = Fund.Public.create_reward(fund, 1500, participant, key)
      {:ok, _} = Fund.Public.reject_reward(key)

      result =
        Ecto.Multi.new()
        |> Ecto.Multi.run(:noop, fn _, _ -> {:ok, :pre} end)
        |> Fund.Public.reject_reward(key)
        |> Core.Repo.commit()

      assert {:ok, %{noop: :pre}} = result
      assert %{status: :rejected} = Fund.Public.get_reward(key, [])
    end
  end
end
