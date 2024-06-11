defmodule Systems.Budget.PublicTest do
  use Core.DataCase

  alias Systems.{
    Budget,
    Bookkeeping
  }

  alias Core.Factories

  setup do
    currency = Budget.Factories.create_currency("fake_currency", :legal, "ƒ", 2)
    budget = Budget.Factories.create_budget("test", currency)
    {:ok, currency: currency, budget: budget}
  end

  test "create_reward/4", %{budget: %{fund: fund, reserve: reserve} = budget} do
    amount = 3500
    %{id: participant_id} = participant = Factories.insert!(:member, %{creator: false})
    reward_idempotence_key = "user:#{participant.id},budget:#{budget.id},assignment:1"
    deposit_idempotence_key = "#{reward_idempotence_key},type=deposit,attempt=0"

    {:ok, %{reward: %{id: reward_id}}} =
      Budget.Public.create_reward(budget, amount, participant, reward_idempotence_key)

    reward =
      Budget.Public.get_reward!(reward_id, [
        [:deposit, :payment, :user, budget: [:fund, :reserve]]
      ])

    journal_message = "Reserved ƒ35.00 on budget #{budget.name} ##{budget.id}"

    fund_balance_credit = fund.balance_credit
    fund_balance_debit = fund.balance_debit + amount

    reserve_balance_credit = reserve.balance_credit + amount
    reserve_balance_debit = reserve.balance_debit

    assert %{
             amount: ^amount,
             user: %{
               id: ^participant_id
             },
             budget: %{
               fund: %{
                 balance_credit: ^fund_balance_credit,
                 balance_debit: ^fund_balance_debit
               },
               reserve: %{
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

  test "rollback_deposit/4 fails without deposit", %{budget: budget} do
    participant = Factories.insert!(:member, %{creator: false})

    reward =
      Factories.insert!(:reward, %{
        idempotence_key: "1",
        amount: 3500,
        attempt: 0,
        user: participant,
        budget: budget
      })

    assert Budget.Public.rollback_deposit(reward) ==
             {:error, :revert_deposit, :deposit_not_available, %{}}
  end

  test "rollback_deposit/4 succeeds with deposit and without payment", %{
    budget: %{id: budget_id, fund: fund, reserve: reserve} = budget
  } do
    amount = 3500

    idempotence_key = "idempotence_key_1"

    participant = Factories.insert!(:member, %{creator: false})

    deposit =
      Factories.insert!(:book_entry, %{
        idempotence_key: idempotence_key,
        journal_message: "test_rollback_deposit"
      })

    Factories.insert!(:book_line, %{account: fund, entry: deposit, debit: amount, credit: 0})
    Factories.insert!(:book_line, %{account: reserve, entry: deposit, debit: 0, credit: amount})

    deposit = Bookkeeping.Public.get_entry(idempotence_key, lines: [:account])

    reward =
      Factories.insert!(:reward, %{
        idempotence_key: "1",
        amount: amount,
        attempt: 0,
        user: participant,
        budget: budget,
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
            }} = Budget.Public.rollback_deposit(reward)

    reverted_deposit = Bookkeeping.Public.get_entry(reverted_idempotence_key, lines: [:account])

    fund_balance_credit = fund.balance_credit + amount
    fund_balance_debit = fund.balance_debit

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
             fund: %{
               balance_credit: ^fund_balance_credit,
               balance_debit: ^fund_balance_debit
             },
             reserve: %{
               balance_credit: ^reserve_balance_credit,
               balance_debit: ^reserve_balance_debit
             }
           } = Budget.Public.get!(budget_id)
  end

  test "rollback_deposit/4 fails with deposit and payment", %{
    budget: %{fund: fund, reserve: reserve} = budget
  } do
    amount = 3500
    deposit_idempotence_key = "idempotence_key_deposit"
    payment_idempotence_key = "idempotence_key_payment"

    participant = Factories.insert!(:member, %{creator: false})

    deposit =
      Bookkeeping.Factories.create_entry(
        fund,
        reserve,
        amount,
        deposit_idempotence_key,
        "test_rollback_deposit"
      )

    payment =
      Bookkeeping.Factories.create_entry(
        fund,
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
        budget: budget,
        deposit: deposit,
        payment: payment
      })

    assert Budget.Public.rollback_deposit(reward) ==
             {:error, :revert_deposit, :payment_already_available, %{}}
  end

  test "payout_reward/4 succeeds with deposit available", %{
    budget: %{id: budget_id, fund: fund, reserve: reserve} = budget
  } do
    amount = 3500
    reward_idempotence_key = "1"
    deposit_idempotence_key = "idempotence_key_deposit"

    deposit =
      Bookkeeping.Factories.create_entry(
        fund,
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
        budget: budget,
        deposit: deposit
      })

    payment_idempotence_key = Budget.RewardModel.payment_idempotence_key(reward)
    assert {:ok, _} = Budget.Public.payout_reward(reward_idempotence_key)

    fund_balance_credit = fund.balance_credit
    fund_balance_debit = fund.balance_debit

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
             fund: %{
               balance_credit: ^fund_balance_credit,
               balance_debit: ^fund_balance_debit
             },
             reserve: %{
               balance_credit: ^reserve_balance_credit,
               balance_debit: ^reserve_balance_debit
             }
           } = Budget.Public.get!(budget_id)
  end

  test "payout_reward/4 succeeds without deposit", %{
    budget: budget
  } do
    amount = 3500

    participant = Factories.insert!(:member, %{creator: false})

    reward_idempotence_key = "1"
    payment_idempotence_key = Budget.RewardModel.payment_idempotence_key(reward_idempotence_key)

    Factories.insert!(:reward, %{
      idempotence_key: reward_idempotence_key,
      amount: amount,
      attempt: 0,
      user: participant,
      budget: budget
    })

    journal_message = "Payout ƒ35.00 on budget #{budget.name} ##{budget.id}"

    assert {:ok,
            %{
              reward: %{
                deposit: nil,
                payment: %{
                  idempotence_key: ^payment_idempotence_key,
                  journal_message: ^journal_message
                }
              }
            }} = Budget.Public.payout_reward(reward_idempotence_key)
  end

  test "payout_reward/4 fails with payment available", %{
    budget: %{currency: currency, fund: fund, reserve: reserve} = budget
  } do
    amount = 3500
    reward_idempotence_key = "1"
    deposit_idempotence_key = "1,type=deposit,attempt=0"
    payment_idempotence_key = "1,type=payment"

    participant = Factories.insert!(:member, %{creator: false})
    wallet = Budget.Factories.create_wallet(participant, currency)

    deposit =
      Bookkeeping.Factories.create_entry(
        fund,
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
      budget: budget,
      deposit: deposit,
      payment: payment
    })

    assert {:error, _, :payment_already_available, _} =
             Budget.Public.payout_reward(reward_idempotence_key)
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

    Budget.Public.move_wallet_balance(
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

    Budget.Public.move_wallet_balance(
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
      Budget.Public.move_wallet_balance(
        ["wallet", "a_b_c_2021", "1"],
        a_b_c_2022.identifier,
        "idempotency_key",
        5000
      )
    end
  end

  test "multiply_rewards/2 succeeds", %{
    budget: %{fund: fund, reserve: reserve} = budget
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
      budget: budget
    })

    Factories.insert!(:reward, %{
      idempotence_key: "participant=2",
      amount: amount,
      attempt: 0,
      user: participant2,
      budget: budget
    })

    Budget.Public.payout_reward("participant=1")
    Budget.Public.payout_reward("participant=2")

    assert %{debit: ^reserve_debit} = Bookkeeping.Public.balance(reserve)
    assert %{debit: ^fund_debit} = Bookkeeping.Public.balance(fund)

    assert [
             %{balance_credit: ^amount},
             %{balance_credit: ^amount}
           ] = Budget.Public.list_wallets(budget)

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
           ] = Budget.Public.multiply_rewards(budget, 10)

    assert %{debit: ^expected_reserve_debit} = Bookkeeping.Public.balance(reserve)
    assert %{debit: ^expected_fund_debit} = Bookkeeping.Public.balance(fund)

    assert [
             %{balance_credit: ^expected_wallet_credit},
             %{balance_credit: ^expected_wallet_credit}
           ] = Budget.Public.list_wallets(budget)
  end
end
