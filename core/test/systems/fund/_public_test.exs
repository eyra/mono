defmodule Systems.Fund.PublicTest do
  use Core.DataCase
  import Mox

  alias Systems.{
    Fund,
    Bookkeeping
  }

  alias Systems.Payment.ProviderMock
  alias Core.Factories

  setup :verify_on_exit!

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

    test "approved_cents only counts :approved rewards (excludes :paid)", %{fund: fund} do
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

      assert %{approved_cents: 100, paid_out_cents: 400} =
               Fund.Public.summarize_rewards(user)
    end

    test "pending_payout_cents sums rewards locked for payout", %{fund: fund} do
      user = Factories.insert!(:member, %{creator: false})

      Factories.insert!(:reward, %{
        user: user,
        fund: fund,
        amount: 250,
        status: :pending_payout,
        idempotence_key: "sr-pendingpayout-250-#{System.unique_integer([:positive])}"
      })

      assert %{approved_cents: 0, pending_payout_cents: 250} =
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

  describe "request_payout/1" do
    setup %{fund: fund} do
      user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_test_123"})
      {:ok, fund: fund, user: user}
    end

    defp insert_reward(user, fund, amount, status) do
      Factories.insert!(:reward, %{
        user: user,
        fund: fund,
        amount: amount,
        status: status,
        idempotence_key: "rp-#{status}-#{amount}-#{System.unique_integer([:positive])}"
      })
    end

    # request_payout/1 re-verifies readiness against fresh OPP state before
    # locking (get_merchant + list_bank_accounts). Stub a fully-ready merchant.
    defp stub_payout_ready(merchant_uid) do
      expect(ProviderMock, :get_merchant, fn ^merchant_uid ->
        {:ok,
         %{
           uid: merchant_uid,
           status: "live",
           kyc_level: 100,
           compliance_status: "verified",
           overview_url: nil
         }}
      end)

      expect(ProviderMock, :list_bank_accounts, fn ^merchant_uid ->
        {:ok, [%{uid: "ba_ok", status: "approved", verification_url: nil}]}
      end)
    end

    # The payout first charges the funds platform (eyra) -> participant merchant,
    # then withdraws. Stub the charge leg as succeeding.
    defp stub_charge_ok do
      expect(ProviderMock, :create_charge, fn _from, _to, _amount, _key ->
        {:ok, %{uid: "chg_ok", status: "created", amount: 0}}
      end)
    end

    test "returns :no_merchant when participant has no merchant_uid", %{fund: fund} do
      user = Factories.insert!(:member, %{creator: false, merchant_uid: nil})
      insert_reward(user, fund, 1000, :approved)

      assert {:error, :no_merchant} = Fund.Public.request_payout(user)
    end

    test "returns :below_threshold when approved balance is under €5", %{user: user, fund: fund} do
      insert_reward(user, fund, 499, :approved)

      assert {:error, {:below_threshold, 499}} = Fund.Public.request_payout(user)
    end

    test "returns :below_threshold with 0 when participant has no approved rewards", %{user: user} do
      assert {:error, {:below_threshold, 0}} = Fund.Public.request_payout(user)
    end

    test "locks approved rewards as :pending_payout on success", %{user: user, fund: fund} do
      %{id: id1} = insert_reward(user, fund, 600, :approved)
      %{id: id2} = insert_reward(user, fund, 400, :approved)

      stub_payout_ready(user.merchant_uid)
      stub_charge_ok()

      expect(ProviderMock, :create_withdrawal, fn _, :EUR, _, _ ->
        {:ok, %{uid: "w_1", status: "created", amount: 1000}}
      end)

      assert {:ok, _} = Fund.Public.request_payout(user)

      assert %{status: :pending_payout} = Fund.Public.get_reward(reward_key(id1), [])
      assert %{status: :pending_payout} = Fund.Public.get_reward(reward_key(id2), [])
    end

    test "calls OPP with the participant's merchant_uid, :EUR, and summed amount",
         %{user: %{merchant_uid: merchant_uid} = user, fund: fund} do
      insert_reward(user, fund, 600, :approved)
      insert_reward(user, fund, 400, :approved)

      stub_payout_ready(merchant_uid)

      # Charge moves the funds platform (eyra) -> participant merchant first.
      expect(ProviderMock, :create_charge, fn "mer_platform_test",
                                              ^merchant_uid,
                                              1000,
                                              "payout=" <> _ ->
        {:ok, %{uid: "chg_2", status: "created", amount: 1000}}
      end)

      expect(ProviderMock, :create_withdrawal, fn ^merchant_uid,
                                                  :EUR,
                                                  %{amount: 1000},
                                                  "payout=" <> _ ->
        {:ok, %{uid: "w_2", status: "created", amount: 1000}}
      end)

      assert {:ok, %{amount: 1000, withdrawal: %{uid: "w_2"}}} =
               Fund.Public.request_payout(user)
    end

    test "reverts the lock when OPP returns an error", %{user: user, fund: fund} do
      %{id: id} = insert_reward(user, fund, 1000, :approved)

      stub_payout_ready(user.merchant_uid)

      # Charge (platform -> participant) fails before any money moves -> revert.
      expect(ProviderMock, :create_charge, fn _, _, _, _ ->
        {:error, %Systems.Payment.Error{code: :http_error, message: "boom"}}
      end)

      assert {:error, {:opp_failed, %Systems.Payment.Error{}}} = Fund.Public.request_payout(user)

      assert %{status: :approved} = Fund.Public.get_reward(reward_key(id), [])
    end

    test "ignores rewards in other statuses when computing the payout", %{user: user, fund: fund} do
      insert_reward(user, fund, 1000, :approved)
      insert_reward(user, fund, 9000, :pending_approval)
      insert_reward(user, fund, 9000, :paid)

      stub_payout_ready(user.merchant_uid)
      stub_charge_ok()

      expect(ProviderMock, :create_withdrawal, fn _, _, %{amount: 1000}, _ ->
        {:ok, %{uid: "w_3", status: "created", amount: 1000}}
      end)

      assert {:ok, %{amount: 1000}} = Fund.Public.request_payout(user)
    end

    test "creates a Fund.Payout aggregate linked to the locked rewards on success",
         %{user: %{id: user_id} = user, fund: fund} do
      %{id: r1_id} = insert_reward(user, fund, 600, :approved)
      %{id: r2_id} = insert_reward(user, fund, 400, :approved)

      stub_payout_ready(user.merchant_uid)
      stub_charge_ok()

      expect(ProviderMock, :create_withdrawal, fn _, :EUR, _, _ ->
        {:ok, %{uid: "w_aggregate_1", status: "created", amount: 1000}}
      end)

      assert {:ok, %{payout: payout}} = Fund.Public.request_payout(user)

      assert %Fund.PayoutModel{
               user_id: ^user_id,
               amount_cents: 1000,
               currency: "eur",
               status: :pending,
               provider_uid: "w_aggregate_1",
               failure_reason: nil
             } = Core.Repo.reload!(payout)

      payout_id = payout.id
      assert %{payout_id: ^payout_id} = Core.Repo.get!(Fund.RewardModel, r1_id)
      assert %{payout_id: ^payout_id} = Core.Repo.get!(Fund.RewardModel, r2_id)
    end

    test "marks the Payout :failed (with reason) and detaches reverted rewards on OPP failure",
         %{user: user, fund: fund} do
      %{id: r_id} = insert_reward(user, fund, 1000, :approved)

      stub_payout_ready(user.merchant_uid)

      expect(ProviderMock, :create_charge, fn _, _, _, _ ->
        {:error, %Systems.Payment.Error{code: :http_error, message: "boom"}}
      end)

      assert {:error, {:opp_failed, _}} = Fund.Public.request_payout(user)

      reward = Core.Repo.get!(Fund.RewardModel, r_id)
      assert reward.status == :approved
      assert reward.payout_id == nil

      [payout] = Core.Repo.all(Fund.PayoutModel)
      assert payout.status == :failed
      assert payout.failure_reason =~ "opp_charge_failed"
      assert payout.provider_uid == nil
    end

    defp reward_key(id) do
      Core.Repo.get!(Fund.RewardModel, id).idempotence_key
    end
  end

  describe "payout_eligibility/1" do
    setup %{fund: fund} do
      user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_elig_1"})
      {:ok, fund: fund, user: user}
    end

    test "returns :below_threshold with the current total when under €5", %{
      user: user,
      fund: fund
    } do
      Factories.insert!(:reward, %{
        user: user,
        fund: fund,
        amount: 499,
        status: :approved,
        idempotence_key: "elig-#{System.unique_integer([:positive])}"
      })

      assert {:error, {:below_threshold, 499}} = Fund.Public.payout_eligibility(user)
    end

    test "returns :ok when at or above €5", %{user: user, fund: fund} do
      Factories.insert!(:reward, %{
        user: user,
        fund: fund,
        amount: 500,
        status: :approved,
        idempotence_key: "elig-#{System.unique_integer([:positive])}"
      })

      assert :ok = Fund.Public.payout_eligibility(user)
    end

    test "does not lock rewards or create a Payout row", %{user: user, fund: fund} do
      Factories.insert!(:reward, %{
        user: user,
        fund: fund,
        amount: 1000,
        status: :approved,
        idempotence_key: "elig-#{System.unique_integer([:positive])}"
      })

      assert :ok = Fund.Public.payout_eligibility(user)

      [reward] = Core.Repo.all(Fund.RewardModel)
      assert reward.status == :approved
      assert reward.payout_id == nil
      assert Core.Repo.all(Fund.PayoutModel) == []
    end
  end

  describe "prepare_payout/1" do
    setup %{fund: fund} do
      user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_prep_1"})
      {:ok, fund: fund, user: user}
    end

    defp eligible_reward(user, fund, amount \\ 1000) do
      Factories.insert!(:reward, %{
        user: user,
        fund: fund,
        amount: amount,
        status: :approved,
        idempotence_key: "prep-#{System.unique_integer([:positive])}"
      })
    end

    # Pre-existing bank account on the merchant — keeps ensure_bank_account_for
    # idempotent in tests that don't care about that step.
    defp stub_existing_bank_account(merchant_uid) do
      expect(ProviderMock, :list_bank_accounts, fn ^merchant_uid ->
        {:ok, [%{uid: "ba_existing", status: "approved", verification_url: nil}]}
      end)
    end

    test "returns :ok when merchant is live + verified AND balance >= threshold",
         %{user: user, fund: fund} do
      eligible_reward(user, fund)

      expect(ProviderMock, :get_merchant, fn "m_prep_1" ->
        {:ok,
         %{
           uid: "m_prep_1",
           status: "live",
           kyc_level: 100,
           compliance_status: "verified",
           overview_url: nil
         }}
      end)

      stub_existing_bank_account("m_prep_1")

      assert :ok = Fund.Public.prepare_payout(user)
    end

    test ~s(returns {:kyc_required, overview_url} when compliance_status != "verified"),
         %{user: user, fund: fund} do
      eligible_reward(user, fund)

      expect(ProviderMock, :get_merchant, fn "m_prep_1" ->
        {:ok,
         %{
           uid: "m_prep_1",
           status: "live",
           kyc_level: 100,
           compliance_status: "unverified",
           overview_url: "https://opp.test/kyc/m_prep_1"
         }}
      end)

      stub_existing_bank_account("m_prep_1")

      assert {:error, {:kyc_required, "https://opp.test/kyc/m_prep_1"}} =
               Fund.Public.prepare_payout(user)
    end

    test ~s(returns {:kyc_required, overview_url} when merchant.status != "live"),
         %{user: user, fund: fund} do
      eligible_reward(user, fund)

      expect(ProviderMock, :get_merchant, fn "m_prep_1" ->
        {:ok,
         %{
           uid: "m_prep_1",
           status: "pending",
           kyc_level: 100,
           compliance_status: "verified",
           overview_url: "https://opp.test/kyc/m_prep_1"
         }}
      end)

      stub_existing_bank_account("m_prep_1")

      assert {:error, {:kyc_required, "https://opp.test/kyc/m_prep_1"}} =
               Fund.Public.prepare_payout(user)
    end

    test "creates a merchant for users with no merchant_uid and persists the uid",
         %{fund: fund} do
      user = Factories.insert!(:member, %{creator: false, merchant_uid: nil})
      eligible_reward(user, fund)

      expect(ProviderMock, :create_merchant, fn %{emailaddress: email} ->
        assert email == user.email

        {:ok,
         %{
           uid: "m_created_inline",
           status: "pending",
           kyc_level: 0,
           compliance_status: "unverified",
           overview_url: "https://opp.test/kyc/m_created_inline"
         }}
      end)

      stub_existing_bank_account("m_created_inline")

      assert {:error, {:kyc_required, "https://opp.test/kyc/m_created_inline"}} =
               Fund.Public.prepare_payout(user)

      assert %{merchant_uid: "m_created_inline"} = Core.Repo.reload!(user)
    end

    test "creates a bank account when none exist for the merchant",
         %{user: user, fund: fund} do
      eligible_reward(user, fund)

      expect(ProviderMock, :get_merchant, fn "m_prep_1" ->
        {:ok,
         %{
           uid: "m_prep_1",
           status: "pending",
           kyc_level: 0,
           compliance_status: "unverified",
           overview_url: "https://opp.test/kyc/m_prep_1"
         }}
      end)

      ProviderMock
      |> expect(:list_bank_accounts, fn "m_prep_1" -> {:ok, []} end)
      |> expect(:create_bank_account, fn "m_prep_1", attrs ->
        # Caller supplies notify_url and return_url so OPP can complete
        # the verification round-trip.
        assert is_binary(attrs.notify_url)
        assert is_binary(attrs.return_url)

        {:ok, %{uid: "ba_new", status: "new", verification_url: "https://opp.test/ba/verify"}}
      end)

      # Merchant is not yet verified, so routing prefers the merchant overview.
      assert {:error, {:kyc_required, "https://opp.test/kyc/m_prep_1"}} =
               Fund.Public.prepare_payout(user)
    end

    test "returns :below_threshold WITHOUT calling OPP when balance is too low",
         %{user: user, fund: fund} do
      eligible_reward(user, fund, 100)
      # No ProviderMock expectation -> Mox would fail if get_merchant was called.

      assert {:error, {:below_threshold, 100}} = Fund.Public.prepare_payout(user)
    end

    test "returns :kyc_unavailable when not ready and OPP gives no usable URL",
         %{user: user, fund: fund} do
      eligible_reward(user, fund)

      expect(ProviderMock, :get_merchant, fn "m_prep_1" ->
        {:ok,
         %{
           uid: "m_prep_1",
           status: "pending",
           kyc_level: 0,
           compliance_status: "unverified",
           overview_url: nil
         }}
      end)

      stub_existing_bank_account("m_prep_1")

      assert {:error, :kyc_unavailable} = Fund.Public.prepare_payout(user)
    end

    test "falls back to the bank verification_url when the merchant has no overview_url",
         %{user: user, fund: fund} do
      eligible_reward(user, fund)

      expect(ProviderMock, :get_merchant, fn "m_prep_1" ->
        {:ok,
         %{
           uid: "m_prep_1",
           status: "live",
           kyc_level: 100,
           compliance_status: "verified",
           overview_url: nil
         }}
      end)

      expect(ProviderMock, :list_bank_accounts, fn "m_prep_1" ->
        {:ok,
         [%{uid: "ba_pending", status: "new", verification_url: "https://opp.test/ba/verify"}]}
      end)

      assert {:error, {:kyc_required, "https://opp.test/ba/verify"}} =
               Fund.Public.prepare_payout(user)
    end

    test "is NOT :ok when merchant is verified but the bank account is not approved",
         %{user: user, fund: fund} do
      eligible_reward(user, fund)

      expect(ProviderMock, :get_merchant, fn "m_prep_1" ->
        {:ok,
         %{
           uid: "m_prep_1",
           status: "live",
           kyc_level: 100,
           compliance_status: "verified",
           overview_url: "https://opp.test/overview/m_prep_1"
         }}
      end)

      expect(ProviderMock, :list_bank_accounts, fn "m_prep_1" ->
        {:ok, [%{uid: "ba_pending", status: "new", verification_url: nil}]}
      end)

      assert {:error, {:kyc_required, "https://opp.test/overview/m_prep_1"}} =
               Fund.Public.prepare_payout(user)
    end
  end

  describe "apply_withdrawal_status/2" do
    setup %{fund: fund} do
      user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_apply_1"})
      {:ok, fund: fund, user: user}
    end

    defp insert_pending_payout(user, fund, amounts, provider_uid) do
      total = Enum.sum(amounts)

      payout =
        Core.Repo.insert!(%Fund.PayoutModel{
          user_id: user.id,
          amount_cents: total,
          currency: "eur",
          status: :pending,
          provider_uid: provider_uid
        })

      rewards =
        Enum.map(amounts, fn amount ->
          Factories.insert!(:reward, %{
            user: user,
            fund: fund,
            amount: amount,
            status: :pending_payout,
            payout_id: payout.id,
            idempotence_key: "apply-#{System.unique_integer([:positive])}"
          })
        end)

      {payout, rewards}
    end

    test ~s(maps OPP "completed" to Payout :completed and rewards :paid),
         %{user: user, fund: fund} do
      {payout, [r1, r2]} = insert_pending_payout(user, fund, [600, 400], "w_completed_1")

      assert {:ok, %Fund.PayoutModel{status: :completed, failure_reason: nil}} =
               Fund.Public.apply_withdrawal_status("w_completed_1", "completed")

      assert %{status: :paid} = Core.Repo.reload!(r1)
      assert %{status: :paid} = Core.Repo.reload!(r2)
      assert %{status: :completed} = Core.Repo.reload!(payout)
    end

    test ~s(maps OPP "failed" to Payout :failed and leaves rewards :pending_payout),
         %{user: user, fund: fund} do
      {payout, [r1]} = insert_pending_payout(user, fund, [1000], "w_failed_1")

      assert {:ok, %Fund.PayoutModel{status: :failed, failure_reason: reason}} =
               Fund.Public.apply_withdrawal_status("w_failed_1", "failed")

      assert reason =~ "failed"
      # The charge already funded the participant merchant, so the rewards stay
      # locked (:pending_payout) for reconciliation rather than reverting to
      # :approved (a re-payout would charge the platform again).
      assert %{status: :pending_payout} = Core.Repo.reload!(r1)
      assert %{status: :failed, failure_reason: ^reason} = Core.Repo.reload!(payout)
    end

    test ~s(maps OPP "disapproved" to Payout :failed with a disapproved reason),
         %{user: user, fund: fund} do
      {payout, [r1]} = insert_pending_payout(user, fund, [1000], "w_disapproved_1")

      assert {:ok, %Fund.PayoutModel{status: :failed, failure_reason: reason}} =
               Fund.Public.apply_withdrawal_status("w_disapproved_1", "disapproved")

      assert reason =~ "disapproved"
      assert %{status: :pending_payout} = Core.Repo.reload!(r1)
      assert %{status: :failed} = Core.Repo.reload!(payout)
    end

    test "intermediate OPP statuses (approved/pending/new) are no-ops",
         %{user: user, fund: fund} do
      {payout, [r1]} = insert_pending_payout(user, fund, [1000], "w_intermediate_1")

      for opp_status <- ["approved", "pending", "new", "unknown_future_value"] do
        assert :ok = Fund.Public.apply_withdrawal_status("w_intermediate_1", opp_status)
      end

      # Nothing should have moved from the original :pending / :pending_payout state.
      assert %{status: :pending_payout} = Core.Repo.reload!(r1)
      assert %{status: :pending} = Core.Repo.reload!(payout)
    end

    test "returns :ok and does nothing when the provider_uid is unknown" do
      assert :ok = Fund.Public.apply_withdrawal_status("w_unknown_999", "completed")
    end

    test "is idempotent: re-applying to an already-:completed payout short-circuits",
         %{user: user, fund: fund} do
      {payout, [r1]} = insert_pending_payout(user, fund, [1000], "w_idempotent_completed")

      assert {:ok, _} = Fund.Public.apply_withdrawal_status("w_idempotent_completed", "completed")
      assert %{status: :paid} = Core.Repo.reload!(r1)

      # A second "completed" webhook must not flip the (now :paid) reward back
      # to :pending_payout or otherwise change state.
      assert {:ok, %Fund.PayoutModel{status: :completed}} =
               Fund.Public.apply_withdrawal_status("w_idempotent_completed", "completed")

      assert %{status: :paid} = Core.Repo.reload!(r1)
      assert %{status: :completed} = Core.Repo.reload!(payout)
    end

    test "is idempotent: a stray late status after :failed does not re-transition",
         %{user: user, fund: fund} do
      {payout, [r1]} = insert_pending_payout(user, fund, [1000], "w_idempotent_failed")

      assert {:ok, _} = Fund.Public.apply_withdrawal_status("w_idempotent_failed", "failed")
      assert %{status: :pending_payout} = Core.Repo.reload!(r1)

      # Late "completed" must not flip a :failed payout to :completed or move
      # the still-locked reward.
      assert {:ok, %Fund.PayoutModel{status: :failed}} =
               Fund.Public.apply_withdrawal_status("w_idempotent_failed", "completed")

      assert %{status: :pending_payout} = Core.Repo.reload!(r1)
      assert %{status: :failed} = Core.Repo.reload!(payout)
    end
  end
end
