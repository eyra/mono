defmodule Systems.Budget.Factories do
  alias Systems.{
    Budget
  }

  def create_currency(name, sign, decimal_scale) do
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

  def create_reward(assignment, user, budget, amount \\ 2) do
    idempotence_key = "assignment=#{assignment.id},user=#{user.id}"

    Core.Factories.insert!(:reward, %{
      amount: amount,
      user: user,
      budget: budget,
      idempotence_key: idempotence_key
    })
  end

  def create_wallet(
        %Core.Accounts.User{id: user_id},
        %Budget.CurrencyModel{name: currency_name},
        balance_credit \\ 0,
        balance_debit \\ 0
      ) do
    Core.Factories.insert!(:book_account, %{
      identifier: ["wallet", currency_name, "#{user_id}"],
      balance_credit: balance_credit,
      balance_debit: balance_debit
    })
  end
end
