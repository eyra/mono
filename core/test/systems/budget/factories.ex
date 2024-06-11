defmodule Systems.Budget.Factories do
  alias Systems.{
    Budget
  }

  def create_currency(name, type, sign, decimal_scale) do
    label_bundle = Core.Factories.insert!(:text_bundle, %{})

    label_items = [
      Core.Factories.insert!(:text_item, %{
        bundle: label_bundle,
        locale: "nl",
        text: "#{sign}%{amount}"
      }),
      Core.Factories.insert!(:text_item, %{
        bundle: label_bundle,
        locale: "en",
        text: "#{sign}%{amount}"
      })
    ]

    label_bundle = Map.put(label_bundle, :items, label_items)

    Core.Factories.insert!(:currency, %{
      name: name,
      type: type,
      label_bundle: label_bundle,
      decimal_scale: decimal_scale
    })
  end

  def create_budget(name, currency) do
    fund =
      Core.Factories.insert!(:book_account, %{
        identifier: ["fund", name],
        balance_debit: 5000,
        balance_credit: 10_000
      })

    reserve =
      Core.Factories.insert!(:book_account, %{
        identifier: ["reserve", name],
        balance_debit: 0,
        balance_credit: 5000
      })

    auth_node = Core.Factories.insert!(:auth_node)

    Core.Factories.insert!(:budget, %{
      name: name,
      currency: currency,
      fund: fund,
      reserve: reserve,
      auth_node: auth_node
    })
  end

  def create_bank_account(name, icon, currency) do
    account =
      Core.Factories.insert!(:book_account, %{
        identifier: ["bank", name],
        balance_debit: 0,
        balance_credit: 0
      })

    Core.Factories.insert!(:bank_account, %{
      name: name,
      icon: icon,
      currency: currency,
      account: account
    })
  end

  def create_reward(assignment, user, budget, amount \\ 2) do
    idempotence_key = "assignment=#{assignment.id},user=#{user.id}"

    Core.Factories.insert!(:reward, %{
      amount: amount,
      user: user,
      budget: budget,
      idempotence_key: idempotence_key
    })
  end

  def create_wallet(user, currency, balance_credit \\ 0, balance_debit \\ 0)

  def create_wallet(
        %Systems.Account.User{id: user_id},
        %Budget.CurrencyModel{} = currency,
        balance_credit,
        balance_debit
      ) do
    create_wallet(user_id, currency, balance_credit, balance_debit)
  end

  def create_wallet(
        user_id,
        %Budget.CurrencyModel{name: currency_name},
        balance_credit,
        balance_debit
      ) do
    Core.Factories.insert!(:book_account, %{
      identifier: ["wallet", currency_name, "#{user_id}"],
      balance_credit: balance_credit,
      balance_debit: balance_debit
    })
  end
end
