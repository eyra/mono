defmodule Systems.Fund.Factories do
  @moduledoc false
  alias Systems.Account.User
  alias Systems.Fund

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

  def create_fund(name, currency) do
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

    Core.Factories.insert!(:fund, %{
      name: name,
      currency: currency,
      available: fund,
      pending: reserve,
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

  def insert_pay_in!(%Fund.Model{id: fund_id}, %User{id: user_id}) do
    %Fund.TransactionModel{}
    |> Fund.TransactionModel.changeset(%{
      transaction_id: "tx_#{System.unique_integer([:positive])}",
      status: :completed,
      idempotence_key: Ecto.UUID.generate(),
      invoice_id: "INV-#{System.unique_integer([:positive])}",
      subject_count: 1,
      total_amount: 100
    })
    |> Ecto.Changeset.put_change(:user_id, user_id)
    |> Ecto.Changeset.put_change(:target_fund_id, fund_id)
    |> Core.Repo.insert!()
  end

  def create_reward(assignment, user, fund, amount \\ 2) do
    idempotence_key = "assignment=#{assignment.id},user=#{user.id}"

    Core.Factories.insert!(:reward, %{
      amount: amount,
      user: user,
      fund: fund,
      idempotence_key: idempotence_key
    })
  end

  def create_wallet(user, currency, balance_credit \\ 0, balance_debit \\ 0)

  def create_wallet(
        %User{id: user_id},
        %Fund.CurrencyModel{} = currency,
        balance_credit,
        balance_debit
      ) do
    create_wallet(user_id, currency, balance_credit, balance_debit)
  end

  def create_wallet(
        user_id,
        %Fund.CurrencyModel{name: currency_name},
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
