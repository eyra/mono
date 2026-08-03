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

  test "create_reward/4 rejects a negative amount without touching the ledger", %{fund: fund} do
    participant = Factories.insert!(:member, %{creator: false})

    assert {:error, :non_positive_amount} =
             Fund.Public.create_reward(fund, -500, participant, "neg-key")

    assert Repo.all(Fund.RewardModel) == []
  end

  test "create_reward/4 rejects a zero amount", %{fund: fund} do
    participant = Factories.insert!(:member, %{creator: false})

    assert {:error, :non_positive_amount} =
             Fund.Public.create_reward(fund, 0, participant, "zero-key")

    assert Repo.all(Fund.RewardModel) == []
  end

  test "create_reward/5 injects a clean failure for a non-positive amount", %{fund: fund} do
    participant = Factories.insert!(:member, %{creator: false})

    assert {:error, :create_reward, :non_positive_amount, _changes} =
             Ecto.Multi.new()
             |> Fund.Public.create_reward(fund, -500, participant, "neg-key-multi")
             |> Repo.commit()

    assert Repo.all(Fund.RewardModel) == []
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

      # Total (4500) must fit the fund's 5000 available: the balance guard now
      # reads the live balance, so an over-budget reservation is refused.
      {:ok, _} = Fund.Public.create_reward(fund, 1000, u1, "k1")
      {:ok, _} = Fund.Public.create_reward(fund, 2000, u2, "k2")
      {:ok, _} = Fund.Public.create_reward(fund, 1500, u3, "k3")

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

  describe "list_rejected_rewards/2" do
    setup %{fund: fund} do
      user = Factories.insert!(:member, %{creator: false})

      rejected =
        Factories.insert!(:reward, %{
          idempotence_key: "rejected-1",
          amount: 500,
          status: :rejected,
          user: user,
          fund: fund
        })

      {:ok, fund: fund, user: user, rejected: rejected}
    end

    test "returns only :rejected rewards for the fund",
         %{fund: fund, user: %{id: user_id}, rejected: %{id: rejected_id}} do
      assert [%{id: ^rejected_id, status: :rejected, user: %{id: ^user_id}}] =
               Fund.Public.list_rejected_rewards(fund)
    end

    test "excludes rewards in other statuses", %{fund: fund, user: user} do
      Factories.insert!(:reward, %{
        idempotence_key: "pending-1",
        amount: 500,
        status: :pending_approval,
        user: user,
        fund: fund
      })

      Factories.insert!(:reward, %{
        idempotence_key: "paid-1",
        amount: 500,
        status: :paid,
        user: user,
        fund: fund
      })

      assert [%{status: :rejected}] = Fund.Public.list_rejected_rewards(fund)
    end

    test "returns empty list for an unrelated fund" do
      currency = Fund.Factories.create_currency("iso-rejected", :legal, "Ω", 2)
      other_fund = Fund.Factories.create_fund("other-rejected", currency)
      assert [] = Fund.Public.list_rejected_rewards(other_fund)
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

    test "flips reward to :rejected with a rejected_at timestamp", %{key: key} do
      assert {:ok, _} = Fund.Public.reject_reward(key)

      reward = Fund.Public.get_reward(key, [])
      assert reward.status == :rejected
      refute is_nil(reward.rejected_at)
    end

    test "approve_reward overrides a rejected reward, paying from fund.available",
         %{key: key, fund: %{id: fund_id}} do
      {:ok, _} = Fund.Public.reject_reward(key)
      assert %{status: :rejected} = Fund.Public.get_reward(key, [])

      assert {:ok, _} = Fund.Public.approve_reward(key)

      reward = Fund.Public.get_reward(key, [])
      assert reward.status == :approved
      assert is_nil(reward.rejected_at)
      refute is_nil(reward.payment_id)

      _ = fund_id
    end

    test "approve_reward of a rejected reward errors when fund.available is insufficient",
         %{key: key, fund: %{id: fund_id}} do
      {:ok, _} = Fund.Public.reject_reward(key)

      drain_amount = Fund.Model.amount_available(Fund.Public.get!(fund_id))

      Fund.Public.get!(fund_id).available
      |> Ecto.Changeset.change(%{balance_debit: drain_amount + 100_000})
      |> Core.Repo.update!()

      assert {:error, :insufficient_fund} = Fund.Public.approve_reward(key)
    end
  end

  describe "summarize_rewards/2" do
    test "returns all zeros when the user has no rewards", %{currency: currency} do
      user = Factories.insert!(:member, %{creator: false})

      assert %{pending_cents: 0, approved_cents: 0, rejected_cents: 0} =
               Fund.Public.summarize_rewards(user, currency.name)
    end

    test "sums :reserved and :pending_approval into pending_cents", %{
      currency: currency,
      fund: fund
    } do
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
               Fund.Public.summarize_rewards(user, currency.name)
    end

    test "approved_cents only counts :approved rewards (excludes :paid)", %{
      currency: currency,
      fund: fund
    } do
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
               Fund.Public.summarize_rewards(user, currency.name)
    end

    test "pending_payout_cents sums rewards locked for payout", %{currency: currency, fund: fund} do
      user = Factories.insert!(:member, %{creator: false})

      Factories.insert!(:reward, %{
        user: user,
        fund: fund,
        amount: 250,
        status: :pending_payout,
        idempotence_key: "sr-pendingpayout-250-#{System.unique_integer([:positive])}"
      })

      assert %{approved_cents: 0, pending_payout_cents: 250} =
               Fund.Public.summarize_rewards(user, currency.name)
    end

    test "sums :rejected into rejected_cents", %{currency: currency, fund: fund} do
      user = Factories.insert!(:member, %{creator: false})

      Factories.insert!(:reward, %{
        user: user,
        fund: fund,
        amount: 75,
        status: :rejected,
        idempotence_key: "sr-rejected-75-#{System.unique_integer([:positive])}"
      })

      assert %{pending_cents: 0, approved_cents: 0, rejected_cents: 75} =
               Fund.Public.summarize_rewards(user, currency.name)
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
    setup do
      user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_test_123"})
      {:ok, fund: euro_fund(), user: user}
    end

    # Payouts settle in EUR, so the payout paths only see euro-fund rewards
    # (see list_approved_rewards); tests exercise them against a euro fund.
    defp euro_fund do
      euro = Fund.Factories.create_currency("euro", :legal, "€", 2)
      Fund.Factories.create_fund("euro-fund-#{System.unique_integer([:positive])}", euro)
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
    # locking (list_bank_accounts only — the bank account gates the payout).
    defp stub_payout_ready(merchant_uid) do
      expect(ProviderMock, :list_bank_accounts, fn ^merchant_uid ->
        {:ok, [%{uid: "ba_ok", status: "approved", verification_url: nil}]}
      end)
    end

    # The payout first charges the funds platform (eyra) -> participant merchant,
    # then withdraws. Stub the charge leg as succeeding.
    defp stub_charge_ok do
      expect(ProviderMock, :transfer_to_merchant, fn _from, _to, _amount, _key ->
        {:ok, %{uid: "chg_ok", status: "created", amount: 0}}
      end)
    end

    test "returns :no_merchant when participant has no merchant_uid", %{fund: fund} do
      user = Factories.insert!(:member, %{creator: false, merchant_uid: nil})
      insert_reward(user, fund, 1000, :approved)

      assert {:error, :no_merchant} = Fund.Public.request_payout(user, "euro")
    end

    test "returns :below_threshold when approved balance is under €5", %{user: user, fund: fund} do
      insert_reward(user, fund, 499, :approved)

      assert {:error, {:below_threshold, 499}} = Fund.Public.request_payout(user, "euro")
    end

    test "returns :below_threshold with 0 when participant has no approved rewards", %{user: user} do
      assert {:error, {:below_threshold, 0}} = Fund.Public.request_payout(user, "euro")
    end

    test "locks approved rewards as :pending_payout on success", %{user: user, fund: fund} do
      %{id: id1} = insert_reward(user, fund, 600, :approved)
      %{id: id2} = insert_reward(user, fund, 400, :approved)

      stub_payout_ready(user.merchant_uid)
      stub_charge_ok()

      expect(ProviderMock, :create_withdrawal, fn _, :EUR, _, _ ->
        {:ok, %{uid: "w_1", status: "created", amount: 1000}}
      end)

      assert {:ok, _} = Fund.Public.request_payout(user, "euro")

      assert %{status: :pending_payout} = Fund.Public.get_reward(reward_key(id1), [])
      assert %{status: :pending_payout} = Fund.Public.get_reward(reward_key(id2), [])
    end

    test "calls OPP with the participant's merchant_uid, :EUR, and summed amount",
         %{user: %{merchant_uid: merchant_uid} = user, fund: fund} do
      insert_reward(user, fund, 600, :approved)
      insert_reward(user, fund, 400, :approved)

      stub_payout_ready(merchant_uid)

      # Charge moves the funds platform (eyra) -> participant merchant first.
      expect(ProviderMock, :transfer_to_merchant, fn "mer_platform_test",
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
               Fund.Public.request_payout(user, "euro")
    end

    test "pays out only euro rewards, leaving other-currency rewards :approved",
         %{user: %{merchant_uid: merchant_uid} = user, fund: euro_fund} do
      insert_reward(user, euro_fund, 600, :approved)

      dollar = Fund.Factories.create_currency("dollar", :legal, "$", 2)

      dollar_fund =
        Fund.Factories.create_fund("usd-fund-#{System.unique_integer([:positive])}", dollar)

      %{id: dollar_reward_id} = insert_reward(user, dollar_fund, 600, :approved)

      stub_payout_ready(merchant_uid)

      # Only the 600 euro cents move — the 600 dollar cents are not summed in.
      expect(ProviderMock, :transfer_to_merchant, fn _from, ^merchant_uid, 600, _key ->
        {:ok, %{uid: "chg_eur", status: "created", amount: 600}}
      end)

      expect(ProviderMock, :create_withdrawal, fn ^merchant_uid, :EUR, %{amount: 600}, _key ->
        {:ok, %{uid: "w_eur", status: "created", amount: 600}}
      end)

      assert {:ok, %{amount: 600}} = Fund.Public.request_payout(user, "euro")

      assert %{status: :approved} = Fund.Public.get_reward(reward_key(dollar_reward_id), [])
    end

    test "reverts the lock when the provider definitively rejects the transfer",
         %{user: user, fund: fund} do
      %{id: id} = insert_reward(user, fund, 1000, :approved)

      stub_payout_ready(user.merchant_uid)

      # A 4xx means the provider received the transfer and refused it before
      # moving any money, so releasing the lock is safe.
      expect(ProviderMock, :transfer_to_merchant, fn _, _, _, _ ->
        {:error, %Systems.Payment.Error{code: :api_error, details: %{status: 422}}}
      end)

      assert {:error, {:opp_failed, %Systems.Payment.Error{}}} =
               Fund.Public.request_payout(user, "euro")

      assert %{status: :approved} = Fund.Public.get_reward(reward_key(id), [])
    end

    test "leaves the lock in place when the transfer outcome is uncertain",
         %{user: user, fund: fund} do
      %{id: id} = insert_reward(user, fund, 1000, :approved)

      stub_payout_ready(user.merchant_uid)

      # A dropped connection tells us nothing: the transfer may have moved the
      # money. Reverting would let a retry charge again, so the rewards stay
      # locked and the payout stays :pending for reconciliation.
      expect(ProviderMock, :transfer_to_merchant, fn _, _, _, _ ->
        {:error, %Systems.Payment.Error{code: :connection_error, message: "boom"}}
      end)

      assert {:error, {:opp_uncertain, %Systems.Payment.Error{}}} =
               Fund.Public.request_payout(user, "euro")

      assert %{status: :pending_payout} = Fund.Public.get_reward(reward_key(id), [])

      [payout] = Core.Repo.all(Fund.PayoutModel)
      assert payout.status == :pending
    end

    test "rolls back without an OPP charge when the rewards are locked concurrently",
         %{user: user, fund: fund} do
      %{id: id} = insert_reward(user, fund, 1000, :approved)

      # Simulate a concurrent payout (other tab/device) that locks these rewards
      # during this request's OPP readiness recheck. list_bank_accounts runs
      # inside recheck_payout_ready, just before lock_for_payout's compare-and-swap.
      expect(ProviderMock, :list_bank_accounts, fn _merchant_uid ->
        Core.Repo.get!(Fund.RewardModel, id)
        |> Ecto.Changeset.change(%{status: :pending_payout})
        |> Core.Repo.update!()

        {:ok, [%{uid: "ba_ok", status: "approved", verification_url: nil}]}
      end)

      # No transfer_to_merchant / create_withdrawal expectations: the compare-and-swap
      # lock must find 0 approved rows and bail before any money moves. Mox's
      # verify_on_exit! raises if either OPP call is made.
      assert {:error, :lock_failed} = Fund.Public.request_payout(user, "euro")

      # The losing attempt's payout insert was rolled back with the failed lock.
      assert Core.Repo.all(Fund.PayoutModel) == []
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

      assert {:ok, %{amount: 1000}} = Fund.Public.request_payout(user, "euro")
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

      assert {:ok, %{payout: payout}} = Fund.Public.request_payout(user, "euro")

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

    test "marks the Payout :failed (with reason) and detaches reverted rewards on a rejected transfer",
         %{user: user, fund: fund} do
      %{id: r_id} = insert_reward(user, fund, 1000, :approved)

      stub_payout_ready(user.merchant_uid)

      expect(ProviderMock, :transfer_to_merchant, fn _, _, _, _ ->
        {:error, %Systems.Payment.Error{code: :api_error, details: %{status: 422}}}
      end)

      assert {:error, {:opp_failed, _}} = Fund.Public.request_payout(user, "euro")

      reward = Core.Repo.get!(Fund.RewardModel, r_id)
      assert reward.status == :approved
      assert reward.payout_id == nil

      [payout] = Core.Repo.all(Fund.PayoutModel)
      assert payout.status == :failed
      assert payout.failure_reason =~ "transfer_rejected"
      assert payout.provider_uid == nil
    end

    # The shortchange fix: a participant with a stranded payout must not have a
    # fresh one started for only their newly-earned rewards — that would silently
    # abandon the money locked on the stranded payout.
    test "resumes an unresolved payout instead of starting a new one",
         %{user: user, fund: fund} do
      # Stranded: funds moved to the participant merchant, no withdrawal recorded.
      stranded =
        Core.Repo.insert!(%Fund.PayoutModel{
          user_id: user.id,
          amount_cents: 1000,
          currency: "eur",
          status: :pending,
          funds_committed_at: ~N[2026-07-15 08:00:00],
          provider_uid: nil
        })

      locked =
        insert_reward(user, fund, 1000, :pending_payout)
        |> Ecto.Changeset.change(%{payout_id: stranded.id})
        |> Core.Repo.update!()

      # A newly-earned reward the participant would be shortchanged out of.
      fresh = insert_reward(user, fund, 500, :approved)

      # Resume drives the stranded payout: it looks for an existing withdrawal
      # (none) and issues one. No new payout, no charge, no bank recheck.
      expect(ProviderMock, :list_withdrawals, fn "m_test_123" -> {:ok, []} end)

      expect(ProviderMock, :create_withdrawal, fn "m_test_123", :EUR, %{amount: 1000}, _key ->
        {:ok,
         %{
           uid: "w_resumed",
           status: :pending,
           raw_status: "created",
           reference: nil,
           amount: 1000
         }}
      end)

      assert {:ok, _} = Fund.Public.request_payout(user, "euro")

      # Exactly one payout — the stranded one, now driven forward.
      assert [%{id: id, provider_uid: "w_resumed"}] = Core.Repo.all(Fund.PayoutModel)
      assert id == stranded.id

      # The locked reward stays with it; the fresh reward is untouched, to be paid
      # out on a later request once this payout resolves.
      assert %{status: :pending_payout, payout_id: ^id} = Core.Repo.reload!(locked)
      assert %{status: :approved, payout_id: nil} = Core.Repo.reload!(fresh)
    end

    # The unconfirmed-transfer case: the money may or may not have moved and no
    # charge can be looked up, so request_payout must surface it for manual review
    # — never start a fresh payout over the approved rewards (risking a double
    # charge) nor touch them.
    test "surfaces :manual_review for an unresolved awaiting-transfer payout, leaving rewards approved",
         %{user: user, fund: fund} do
      stranded =
        Core.Repo.insert!(%Fund.PayoutModel{
          user_id: user.id,
          amount_cents: 1000,
          currency: "eur",
          status: :pending,
          funds_committed_at: nil,
          provider_uid: nil
        })

      # A newly-earned reward that must not be swept into a fresh payout.
      fresh = insert_reward(user, fund, 500, :approved)

      # No provider calls at all: an unconfirmed transfer with no findable charge
      # is left for a human — nothing is issued and no bank recheck happens.
      assert {:error, :manual_review} = Fund.Public.request_payout(user, "euro")

      # Still exactly one payout (the stranded one); the fresh reward is untouched.
      assert [%{id: id}] = Core.Repo.all(Fund.PayoutModel)
      assert id == stranded.id
      assert %{status: :approved, payout_id: nil} = Core.Repo.reload!(fresh)
    end

    # A :failed payout that moved no money already released its lock, so it must
    # not block a fresh payout of the reverted (now :approved) rewards.
    test "starts a new payout when the only prior one failed before moving money",
         %{user: user, fund: fund} do
      Core.Repo.insert!(%Fund.PayoutModel{
        user_id: user.id,
        amount_cents: 1000,
        currency: "eur",
        status: :failed,
        funds_committed_at: nil,
        provider_uid: nil
      })

      insert_reward(user, fund, 1000, :approved)

      stub_payout_ready(user.merchant_uid)
      stub_charge_ok()

      expect(ProviderMock, :create_withdrawal, fn _, :EUR, _, _ ->
        {:ok,
         %{uid: "w_fresh", status: :pending, raw_status: "created", reference: nil, amount: 1000}}
      end)

      assert {:ok, %{payout: %{provider_uid: "w_fresh"}}} =
               Fund.Public.request_payout(user, "euro")
    end

    defp reward_key(id) do
      Core.Repo.get!(Fund.RewardModel, id).idempotence_key
    end
  end

  describe "resume_payout/1" do
    setup %{fund: fund} do
      user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_resume_1"})
      {:ok, fund: fund, user: user}
    end

    defp stranded_payout(user, fund, attrs) do
      payout =
        Core.Repo.insert!(
          struct!(
            %Fund.PayoutModel{
              user_id: user.id,
              amount_cents: 1000,
              currency: "eur",
              status: :pending
            },
            attrs
          )
        )

      reward =
        Factories.insert!(:reward, %{
          user: user,
          fund: fund,
          amount: 1000,
          status: :pending_payout,
          payout_id: payout.id,
          idempotence_key: "resume-#{System.unique_integer([:positive])}"
        })

      {payout, reward}
    end

    # :awaiting_withdrawal, and the withdrawal was created at the provider but its
    # uid was never recorded. Resume must adopt the existing one, not issue a new
    # one (that would withdraw twice).
    test "adopts an existing withdrawal found by reference instead of issuing another",
         %{user: user, fund: fund} do
      {payout, reward} =
        stranded_payout(user, fund, %{
          funds_committed_at: ~N[2026-07-15 08:00:00],
          provider_uid: nil
        })

      prefix = Fund.PayoutModel.withdrawal_key_prefix(payout)

      expect(ProviderMock, :list_withdrawals, fn "m_resume_1" ->
        {:ok,
         [
           %{
             uid: "w_found",
             status: :completed,
             raw_status: "completed",
             reference: prefix <> ",attempt=0",
             amount: 1000
           }
         ]}
      end)

      # No create_withdrawal expectation: issuing one would be a second withdrawal.
      assert {:ok, _} = Fund.Public.resume_payout(payout)

      assert %{status: :completed, provider_uid: "w_found"} = Core.Repo.reload!(payout)
      assert %{status: :paid} = Core.Repo.reload!(reward)
    end

    # :awaiting_withdrawal after a retry whose response was lost: the provider now
    # holds both the rejected attempt=0 and a still-pending attempt=1. Matching by
    # prefix alone could adopt the failed attempt (listed first here), mark the
    # payout :failed, and drive a fresh retry while attempt=1 is still live —
    # paying the participant twice. Resume must adopt the *current* attempt.
    test "adopts the live current attempt, never a stale failed one, when both exist",
         %{user: user, fund: fund} do
      {payout, reward} =
        stranded_payout(user, fund, %{
          funds_committed_at: ~N[2026-07-15 08:00:00],
          provider_uid: nil,
          withdrawal_attempt: 1
        })

      prefix = Fund.PayoutModel.withdrawal_key_prefix(payout)

      expect(ProviderMock, :list_withdrawals, fn "m_resume_1" ->
        {:ok,
         [
           # The earlier, rejected attempt — listed first, must NOT be adopted.
           %{
             uid: "w_failed_0",
             status: :failed,
             raw_status: "disapproved",
             reference: prefix <> ",attempt=0",
             amount: 1000
           },
           # The current attempt, still pending after the lost response.
           %{
             uid: "w_live_1",
             status: :pending,
             raw_status: "pending",
             reference: prefix <> ",attempt=1",
             amount: 1000
           }
         ]}
      end)

      # No create_withdrawal: a live attempt already exists, so nothing new is issued.
      assert {:ok, _} = Fund.Public.resume_payout(payout)

      # Adopts the live current attempt and stays pending — not :failed (which would
      # trigger a double-paying retry).
      assert %{status: :pending, provider_uid: "w_live_1"} = Core.Repo.reload!(payout)
      assert %{status: :pending_payout} = Core.Repo.reload!(reward)
    end

    # :awaiting_withdrawal, and no withdrawal was ever created. Resume must issue
    # one under the current attempt.
    test "issues a withdrawal when the provider holds none for the payout",
         %{user: user, fund: fund} do
      {payout, _reward} =
        stranded_payout(user, fund, %{
          funds_committed_at: ~N[2026-07-15 08:00:00],
          provider_uid: nil
        })

      expect(ProviderMock, :list_withdrawals, fn "m_resume_1" -> {:ok, []} end)

      expect(ProviderMock, :create_withdrawal, fn "m_resume_1", :EUR, %{amount: 1000}, key ->
        assert key =~ "type=withdrawal,attempt=0"

        {:ok,
         %{uid: "w_new", status: :pending, raw_status: "created", reference: key, amount: 1000}}
      end)

      assert {:ok, _} = Fund.Public.resume_payout(payout)
      assert %{status: :pending, provider_uid: "w_new"} = Core.Repo.reload!(payout)
    end

    # :withdrawal_retryable — a withdrawal failed after the money moved. Resume
    # must issue a fresh one under a NEW attempt (the failed one keeps its key).
    test "retries a failed withdrawal under a fresh attempt", %{user: user, fund: fund} do
      {payout, _reward} =
        stranded_payout(user, fund, %{
          status: :failed,
          funds_committed_at: ~N[2026-07-15 08:00:00],
          provider_uid: "w_failed",
          withdrawal_attempt: 0,
          failure_reason: "provider_status: disapproved"
        })

      expect(ProviderMock, :create_withdrawal, fn "m_resume_1", :EUR, %{amount: 1000}, key ->
        # A fresh key, distinct from the failed attempt=0 withdrawal.
        assert key =~ "type=withdrawal,attempt=1"

        {:ok,
         %{uid: "w_retry", status: :pending, raw_status: "created", reference: key, amount: 1000}}
      end)

      assert {:ok, _} = Fund.Public.resume_payout(payout)

      assert %{
               status: :pending,
               provider_uid: "w_retry",
               withdrawal_attempt: 1,
               failure_reason: nil
             } =
               Core.Repo.reload!(payout)
    end

    # :awaiting_transfer — the transfer was never confirmed and a charge cannot be
    # looked up, so resume must not guess. No provider calls at all.
    test "leaves an unconfirmed transfer for manual review", %{user: user, fund: fund} do
      {payout, _reward} =
        stranded_payout(user, fund, %{funds_committed_at: nil, provider_uid: nil})

      assert {:error, :manual_review} = Fund.Public.resume_payout(payout)
      assert %{status: :pending} = Core.Repo.reload!(payout)
    end

    test "is a no-op for a healthy in-flight payout", %{user: user, fund: fund} do
      {payout, _reward} =
        stranded_payout(user, fund, %{
          funds_committed_at: ~N[2026-07-15 08:00:00],
          provider_uid: "w_inflight"
        })

      assert {:ok, {:in_flight, _}} = Fund.Public.resume_payout(payout)
    end

    test "is a no-op for a completed payout", %{user: user, fund: fund} do
      {payout, _reward} =
        stranded_payout(user, fund, %{
          status: :completed,
          funds_committed_at: ~N[2026-07-15 08:00:00],
          provider_uid: "w_done"
        })

      assert {:ok, {:resolved, _}} = Fund.Public.resume_payout(payout)
    end
  end

  describe "payout_status/1" do
    setup %{fund: fund} do
      user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_status_1"})
      {:ok, fund: fund, user: user}
    end

    test "is :none without an unresolved payout", %{user: user} do
      assert :none = Fund.Public.payout_status(user)
    end

    test "is :in_progress while the withdrawal is in flight", %{user: user, fund: fund} do
      stranded_payout(user, fund, %{
        funds_committed_at: ~N[2026-07-15 08:00:00],
        provider_uid: "w_inflight"
      })

      assert :in_progress = Fund.Public.payout_status(user)
    end

    test "is :retryable when funds moved but no withdrawal was recorded",
         %{user: user, fund: fund} do
      stranded_payout(user, fund, %{
        funds_committed_at: ~N[2026-07-15 08:00:00],
        provider_uid: nil
      })

      assert :retryable = Fund.Public.payout_status(user)
    end

    test "is :retryable when a withdrawal failed after the funds moved",
         %{user: user, fund: fund} do
      stranded_payout(user, fund, %{
        status: :failed,
        funds_committed_at: ~N[2026-07-15 08:00:00],
        provider_uid: "w_failed"
      })

      assert :retryable = Fund.Public.payout_status(user)
    end

    test "is :manual when the transfer was never confirmed", %{user: user, fund: fund} do
      stranded_payout(user, fund, %{funds_committed_at: nil, provider_uid: nil})

      assert :manual = Fund.Public.payout_status(user)
    end
  end

  describe "payout_eligibility/1" do
    setup do
      user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_elig_1"})
      {:ok, fund: euro_fund(), user: user}
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

      assert {:error, {:below_threshold, 499}} = Fund.Public.payout_eligibility(user, "euro")
    end

    test "returns :ok when at or above €5", %{user: user, fund: fund} do
      Factories.insert!(:reward, %{
        user: user,
        fund: fund,
        amount: 500,
        status: :approved,
        idempotence_key: "elig-#{System.unique_integer([:positive])}"
      })

      assert :ok = Fund.Public.payout_eligibility(user, "euro")
    end

    test "does not lock rewards or create a Payout row", %{user: user, fund: fund} do
      Factories.insert!(:reward, %{
        user: user,
        fund: fund,
        amount: 1000,
        status: :approved,
        idempotence_key: "elig-#{System.unique_integer([:positive])}"
      })

      assert :ok = Fund.Public.payout_eligibility(user, "euro")

      [reward] = Core.Repo.all(Fund.RewardModel)
      assert reward.status == :approved
      assert reward.payout_id == nil
      assert Core.Repo.all(Fund.PayoutModel) == []
    end
  end

  describe "prepare_payout/1" do
    setup do
      user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_prep_1"})
      {:ok, fund: euro_fund(), user: user}
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

      assert :ok = Fund.Public.prepare_payout(user, "euro")
    end

    test ~s(is :ok with an approved bank even when merchant compliance_status != "verified"),
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

      assert :ok = Fund.Public.prepare_payout(user, "euro")
    end

    test ~s(is :ok with an approved bank even when merchant.status != "live"),
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

      assert :ok = Fund.Public.prepare_payout(user, "euro")
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

      assert :ok = Fund.Public.prepare_payout(user, "euro")

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

      # Freshly created bank account is not yet approved -> drive the iDEAL flow.
      assert {:error, {:kyc_required, :bank, "https://opp.test/ba/verify"}} =
               Fund.Public.prepare_payout(user, "euro")
    end

    test "returns :below_threshold WITHOUT calling OPP when balance is too low",
         %{user: user, fund: fund} do
      eligible_reward(user, fund, 100)
      # No ProviderMock expectation -> Mox would fail if get_merchant was called.

      assert {:error, {:below_threshold, 100}} = Fund.Public.prepare_payout(user, "euro")
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

      # Bank account is not approved and carries no verification_url.
      expect(ProviderMock, :list_bank_accounts, fn "m_prep_1" ->
        {:ok, [%{uid: "ba", status: "new", verification_url: nil}]}
      end)

      assert {:error, :kyc_unavailable} = Fund.Public.prepare_payout(user, "euro")
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

      assert {:error, {:kyc_required, :bank, "https://opp.test/ba/verify"}} =
               Fund.Public.prepare_payout(user, "euro")
    end

    test "is :kyc_unavailable when the bank is not approved, ignoring any merchant overview_url",
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

      # Bank not approved and no verification_url; the merchant overview_url is
      # irrelevant now that a verified bank account is all we require.
      expect(ProviderMock, :list_bank_accounts, fn "m_prep_1" ->
        {:ok, [%{uid: "ba_pending", status: "new", verification_url: nil}]}
      end)

      assert {:error, :kyc_unavailable} = Fund.Public.prepare_payout(user, "euro")
    end

    # Regression: FX#10005449329. After the participant finishes iDEAL, the
    # payment provider puts the bank account in a review state ("pending") but
    # often keeps returning a verification_url. Reporting :kyc_required at that
    # point makes us show the "please verify your bank account" modal — the
    # participant thinks they must redo KYC when in fact they only need to wait.
    test "returns :awaiting_verification when the bank is pending provider review",
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
         [%{uid: "ba_pending", status: "pending", verification_url: "https://opp.test/ba/verify"}]}
      end)

      assert {:error, :awaiting_verification} = Fund.Public.prepare_payout(user, "euro")
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

    # The provider adapter normalizes its own vocabulary before the domain sees
    # it (see Provider.OPPTest); the domain only ever handles these three atoms.
    defp withdrawal(status, raw_status) do
      %{uid: "w_test", status: status, raw_status: raw_status, amount: 0}
    end

    test "maps :completed to Payout :completed and rewards :paid",
         %{user: user, fund: fund} do
      {payout, [r1, r2]} = insert_pending_payout(user, fund, [600, 400], "w_completed_1")

      assert {:ok, %Fund.PayoutModel{status: :completed, failure_reason: nil}} =
               Fund.Public.apply_withdrawal_status(
                 "w_completed_1",
                 withdrawal(:completed, "completed")
               )

      assert %{status: :paid} = Core.Repo.reload!(r1)
      assert %{status: :paid} = Core.Repo.reload!(r2)
      assert %{status: :completed} = Core.Repo.reload!(payout)
    end

    test "maps :failed to Payout :failed and leaves rewards :pending_payout",
         %{user: user, fund: fund} do
      {payout, [r1]} = insert_pending_payout(user, fund, [1000], "w_failed_1")

      assert {:ok, %Fund.PayoutModel{status: :failed, failure_reason: reason}} =
               Fund.Public.apply_withdrawal_status("w_failed_1", withdrawal(:failed, "failed"))

      assert reason =~ "failed"
      # The transfer already funded the participant merchant, so the rewards stay
      # locked (:pending_payout) for reconciliation rather than reverting to
      # :approved (a re-payout would charge the platform again).
      assert %{status: :pending_payout} = Core.Repo.reload!(r1)
      assert %{status: :failed, failure_reason: ^reason} = Core.Repo.reload!(payout)
    end

    test ~s(records the provider's own word, not the normalized atom, as the failure reason),
         %{user: user, fund: fund} do
      {payout, _} = insert_pending_payout(user, fund, [1000], "w_disapproved_1")

      assert {:ok, %Fund.PayoutModel{status: :failed, failure_reason: reason}} =
               Fund.Public.apply_withdrawal_status(
                 "w_disapproved_1",
                 withdrawal(:failed, "disapproved")
               )

      # :failed collapses OPP's "failed" and "disapproved"; the audit trail must
      # still say which one it actually was.
      assert reason =~ "disapproved"
      assert %{status: :failed} = Core.Repo.reload!(payout)
    end

    test ":pending is a no-op regardless of the provider's own word",
         %{user: user, fund: fund} do
      {payout, [r1]} = insert_pending_payout(user, fund, [1000], "w_intermediate_1")

      for raw_status <- ["approved", "pending", "new", "unknown_future_value"] do
        assert {:ok, _} =
                 Fund.Public.apply_withdrawal_status(
                   "w_intermediate_1",
                   withdrawal(:pending, raw_status)
                 )
      end

      # Nothing should have moved from the original :pending / :pending_payout state.
      assert %{status: :pending_payout} = Core.Repo.reload!(r1)
      assert %{status: :pending} = Core.Repo.reload!(payout)
    end

    test "returns {:ok, nil} and does nothing when the provider_uid is unknown" do
      assert {:ok, nil} =
               Fund.Public.apply_withdrawal_status(
                 "w_unknown_999",
                 withdrawal(:completed, "completed")
               )
    end

    test "is idempotent: re-applying to an already-:completed payout short-circuits",
         %{user: user, fund: fund} do
      {payout, [r1]} = insert_pending_payout(user, fund, [1000], "w_idempotent_completed")

      done = withdrawal(:completed, "completed")

      assert {:ok, _} = Fund.Public.apply_withdrawal_status("w_idempotent_completed", done)
      assert %{status: :paid} = Core.Repo.reload!(r1)

      # A second "completed" webhook must not flip the (now :paid) reward back
      # to :pending_payout or otherwise change state.
      assert {:ok, %Fund.PayoutModel{status: :completed}} =
               Fund.Public.apply_withdrawal_status("w_idempotent_completed", done)

      assert %{status: :paid} = Core.Repo.reload!(r1)
      assert %{status: :completed} = Core.Repo.reload!(payout)
    end

    test "is idempotent: a stray late status after :failed does not re-transition",
         %{user: user, fund: fund} do
      {payout, [r1]} = insert_pending_payout(user, fund, [1000], "w_idempotent_failed")

      assert {:ok, _} =
               Fund.Public.apply_withdrawal_status(
                 "w_idempotent_failed",
                 withdrawal(:failed, "failed")
               )

      assert %{status: :pending_payout} = Core.Repo.reload!(r1)

      # Late :completed must not flip a :failed payout to :completed or move
      # the still-locked reward.
      assert {:ok, %Fund.PayoutModel{status: :failed}} =
               Fund.Public.apply_withdrawal_status(
                 "w_idempotent_failed",
                 withdrawal(:completed, "completed")
               )

      assert %{status: :pending_payout} = Core.Repo.reload!(r1)
      assert %{status: :failed} = Core.Repo.reload!(payout)
    end
  end
end
