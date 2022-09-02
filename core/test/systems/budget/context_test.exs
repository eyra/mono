defmodule Systems.Budget.ContextTest do
  use Core.DataCase

  alias Systems.{
    Budget,
    Bookkeeping
  }

  alias Core.Factories

  setup do
    currency = Budget.Factories.create_currency("fake_currency", "ƒ", 2)
    budget = Budget.Factories.create_budget("test", currency)
    {:ok, currency: currency, budget: budget}
  end

  test "create_reward/4", %{budget: %{fund: fund, reserve: reserve} = budget} do
    amount = 3500
    %{id: student_id} = student = Factories.insert!(:member, %{student: true})
    reward_idempotence_key = "user:#{student.id},budget:#{budget.id},assignment:1"
    deposit_idempotence_key = "#{reward_idempotence_key},type=deposit,attempt=0"

    %{id: reward_id} =
      Budget.Context.create_reward!(budget, amount, student, reward_idempotence_key)

    reward =
      Budget.Context.get_reward!(reward_id, [
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
               id: ^student_id
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

  test "rollback_reward/4 fails without deposit", %{budget: budget} do
    student = Factories.insert!(:member, %{student: true})

    reward =
      Factories.insert!(:reward, %{
        idempotence_key: "1",
        amount: 3500,
        attempt: 0,
        user: student,
        budget: budget
      })

    assert Budget.Context.rollback_reward(reward) ==
             {:error, :revert_deposit, :deposit_not_available, %{}}
  end

  test "rollback_reward/4 succeeds with deposit and without payment", %{
    budget: %{id: budget_id, fund: fund, reserve: reserve} = budget
  } do
    amount = 3500

    idempotence_key = "idempotence_key_1"

    student = Factories.insert!(:member, %{student: true})

    deposit =
      Factories.insert!(:book_entry, %{
        idempotence_key: idempotence_key,
        journal_message: "test_rollback_reward"
      })

    Factories.insert!(:book_line, %{account: fund, entry: deposit, debit: amount, credit: 0})
    Factories.insert!(:book_line, %{account: reserve, entry: deposit, debit: 0, credit: amount})

    deposit = Bookkeeping.Context.get_entry(idempotence_key, lines: [:account])

    reward =
      Factories.insert!(:reward, %{
        idempotence_key: "1",
        amount: amount,
        attempt: 0,
        user: student,
        budget: budget,
        deposit: deposit
      })

    assert {:ok,
            %{
              revert_deposit: %{
                validate: true,
                entry: %{
                  idempotence_key: "[REVERT] idempotence_key_1" = reverted_idempotence_key,
                  journal_message: "[REVERT] test_rollback_reward"
                }
              }
            }} = Budget.Context.rollback_reward(reward)

    reverted_deposit = Bookkeeping.Context.get_entry(reverted_idempotence_key, lines: [:account])

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
           } = Budget.Context.get!(budget_id)
  end

  test "rollback_reward/4 fails with deposit and payment", %{
    budget: %{fund: fund, reserve: reserve} = budget
  } do
    amount = 3500
    deposit_idempotence_key = "idempotence_key_deposit"
    payment_idempotence_key = "idempotence_key_payment"

    student = Factories.insert!(:member, %{student: true})

    deposit =
      Bookkeeping.Factories.create_entry(
        fund,
        reserve,
        amount,
        deposit_idempotence_key,
        "test_rollback_reward"
      )

    payment =
      Bookkeeping.Factories.create_entry(
        fund,
        reserve,
        amount,
        payment_idempotence_key,
        "test_rollback_reward"
      )

    reward =
      Factories.insert!(:reward, %{
        idempotence_key: "1",
        amount: amount,
        attempt: 0,
        user: student,
        budget: budget,
        deposit: deposit,
        payment: payment
      })

    assert Budget.Context.rollback_reward(reward) ==
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

    %{id: student_id} = student = Factories.insert!(:member, %{student: true})

    reward =
      Factories.insert!(:reward, %{
        idempotence_key: reward_idempotence_key,
        amount: amount,
        attempt: 0,
        user: student,
        budget: budget,
        deposit: deposit
      })

    payment_idempotence_key = Budget.RewardModel.payment_idempotence_key(reward)
    assert {:ok, _} = Budget.Context.payout_reward(reward_idempotence_key)

    fund_balance_credit = fund.balance_credit
    fund_balance_debit = fund.balance_debit

    reserve_balance_credit = reserve.balance_credit
    reserve_balance_debit = reserve.balance_debit + amount

    wallet_id = ["wallet", "fake_currency", "#{student_id}"]

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
           } = Bookkeeping.Context.get_entry(payment_idempotence_key, lines: [:account])

    assert %{
             fund: %{
               balance_credit: ^fund_balance_credit,
               balance_debit: ^fund_balance_debit
             },
             reserve: %{
               balance_credit: ^reserve_balance_credit,
               balance_debit: ^reserve_balance_debit
             }
           } = Budget.Context.get!(budget_id)
  end

  test "payout_reward/4 succeeds without deposit", %{
    budget: budget
  } do
    amount = 3500

    student = Factories.insert!(:member, %{student: true})

    reward_idempotence_key = "1"
    payment_idempotence_key = Budget.RewardModel.payment_idempotence_key(reward_idempotence_key)

    Factories.insert!(:reward, %{
      idempotence_key: reward_idempotence_key,
      amount: amount,
      attempt: 0,
      user: student,
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
            }} = Budget.Context.payout_reward(reward_idempotence_key)
  end

  test "payout_reward/4 fails with payment available", %{
    budget: %{currency: currency, fund: fund, reserve: reserve} = budget
  } do
    amount = 3500
    reward_idempotence_key = "1"
    deposit_idempotence_key = "1,type=deposit,attempt=0"
    payment_idempotence_key = "1,type=payment"

    student = Factories.insert!(:member, %{student: true})
    wallet = Budget.Factories.create_wallet(student, currency)

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
      user: student,
      budget: budget,
      deposit: deposit,
      payment: payment
    })

    assert {:error, _, :payment_already_available, _} =
             Budget.Context.payout_reward(reward_idempotence_key)
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

    Budget.Context.move_wallet_balance(
      a_b_c_2021.identifier,
      a_b_c_2022.identifier,
      "idempotency_key",
      5001
    )

    assert %{
             balance_credit: 10_000,
             balance_debit: 10_000
           } = Bookkeeping.Context.get_account!(["wallet", "a_b_c_2021", "1"])

    assert %{
             balance_credit: 5000,
             balance_debit: 0
           } = Bookkeeping.Context.get_account!(["wallet", "a_b_c_2022", "1"])
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

    Budget.Context.move_wallet_balance(
      a_b_c_2021.identifier,
      a_b_c_2022.identifier,
      "idempotency_key",
      5000
    )

    assert %{
             balance_credit: 10_000,
             balance_debit: 5000
           } = Bookkeeping.Context.get_account!(["wallet", "a_b_c_2021", "1"])

    assert %{
             balance_credit: 0,
             balance_debit: 0
           } = Bookkeeping.Context.get_account!(["wallet", "a_b_c_2022", "1"])
  end

  test "multiply_rewards/2 succeeds", %{
    budget: %{fund: fund, reserve: reserve} = budget
  } do
    amount = 3500
    multiplier = 10
    expected_mount = amount * (multiplier - 1)

    reserve_debit = 0
    expected_reserve_debit = reserve_debit + 2 * expected_mount

    fund_debit = 12_000
    expected_fund_debit = fund_debit + 2 * expected_mount

    expected_wallet_credit = amount * multiplier

    student1 = Factories.insert!(:member, %{student: true})
    student2 = Factories.insert!(:member, %{student: true})

    Factories.insert!(:reward, %{
      idempotence_key: "student=1",
      amount: amount,
      attempt: 0,
      user: student1,
      budget: budget
    })

    Factories.insert!(:reward, %{
      idempotence_key: "student=2",
      amount: amount,
      attempt: 0,
      user: student2,
      budget: budget
    })

    Budget.Context.payout_reward("student=1")
    Budget.Context.payout_reward("student=2")

    assert %{debit: ^reserve_debit} = Bookkeeping.Context.balance(reserve)
    assert %{debit: ^fund_debit} = Bookkeeping.Context.balance(fund)

    assert [
             %{balance_credit: ^amount},
             %{balance_credit: ^amount}
           ] = Budget.Context.list_wallets(budget)

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
           ] = Budget.Context.multiply_rewards(budget, 10)

    assert %{debit: ^expected_reserve_debit} = Bookkeeping.Context.balance(reserve)
    assert %{debit: ^expected_fund_debit} = Bookkeeping.Context.balance(fund)

    assert [
             %{balance_credit: ^expected_wallet_credit},
             %{balance_credit: ^expected_wallet_credit}
           ] = Budget.Context.list_wallets(budget)
  end
end
