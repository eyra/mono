defmodule Systems.Budget.Public do
  import Ecto.Query, warn: false
  import Ecto.Changeset

  import Systems.Budget.Queries

  require Logger

  alias Ecto.Multi
  alias Core.Repo
  alias Core.Accounts
  alias Core.Authorization

  alias Frameworks.Utility.Identifier

  alias Systems.{
    Budget,
    Bookkeeping,
    Banking
  }

  defmodule BudgetError do
    @moduledoc false
    defexception [:message]
  end

  def list(preload \\ []) do
    Repo.all(Budget.Model) |> Repo.preload(preload)
  end

  def list_owned(%Accounts.User{} = user, preload \\ []) do
    node_ids =
      Authorization.query_node_ids(
        role: :owner,
        principal: user
      )

    from(b in Budget.Model,
      where: b.auth_node_id in subquery(node_ids),
      preload: ^preload
    )
    |> Repo.all()
  end

  def list_owned_by_currency(
        %Accounts.User{} = user,
        %Budget.CurrencyModel{id: currency_id},
        preload \\ []
      ) do
    node_ids =
      Authorization.query_node_ids(
        role: :owner,
        principal: user
      )

    from(b in Budget.Model,
      where: b.auth_node_id in subquery(node_ids),
      where: b.currency_id == ^currency_id,
      preload: ^preload
    )
    |> Repo.all()
  end

  def list_currencies(preload \\ []) do
    currency_query()
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def list_currencies_by_type(type, preload \\ []) do
    currency_query(type)
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def list_bank_accounts(preload \\ []) do
    Repo.all(Budget.BankAccountModel) |> Repo.preload(preload)
  end

  def list_wallets(%Accounts.User{id: user_id}) do
    Bookkeeping.Public.list_accounts(["wallet", "#{user_id}"])
  end

  def list_wallets(%Budget.Model{currency: currency}), do: list_wallets(currency)

  def list_wallets(%Budget.CurrencyModel{name: name}) do
    Bookkeeping.Public.list_accounts(["wallet", "#{name}"])
  end

  def list_rewards(%Accounts.User{id: user_id}, preload \\ []) do
    from(reward in Budget.RewardModel,
      where: reward.user_id == ^user_id,
      preload: ^preload
    )
    |> Repo.all()
  end

  def get!(id, preload \\ [:fund, :reserve]) when is_integer(id) do
    from(budget in Budget.Model, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_by_currency!(%Budget.CurrencyModel{id: currency_id}, preload \\ []) do
    Repo.get_by!(Budget.Model, currency_id: currency_id)
    |> Repo.preload(preload)
  end

  def get_by_name(name, preload \\ []) when is_binary(name) do
    Repo.get_by(Budget.Model, name: name)
    |> Repo.preload(preload)
  end

  def get_bank_account!(id, preload \\ []) when is_integer(id) do
    from(bank_account in Budget.BankAccountModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_currency!(id, preload \\ []) when is_integer(id) do
    from(currency in Budget.CurrencyModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_currency_by_name(name, preload \\ []) when is_binary(name) do
    Repo.get_by(Budget.CurrencyModel, name: name)
    |> Repo.preload(preload)
  end

  def get_reward!(id, preload \\ [:budget, :deposit, :payment, :user]) do
    from(reward in Budget.RewardModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_reward(idempotence_key, preload) when is_binary(idempotence_key) do
    from(reward in Budget.RewardModel,
      where: reward.idempotence_key == ^idempotence_key,
      preload: ^preload
    )
    |> Repo.one()
  end

  def get_reward(%Budget.Model{id: budget_id}, %Accounts.User{id: user_id}, preload \\ []) do
    from(reward in Budget.RewardModel,
      where: reward.user_id == ^user_id,
      where: reward.budget_id == ^budget_id,
      where: not (is_nil(reward.deposit_id) and is_nil(reward.payment_id)),
      preload: ^preload
    )
    |> Repo.one()
  end

  def get_wallet_identifier(%Core.Accounts.User{} = user, %Budget.CurrencyModel{
        name: currency_name
      }),
      do: get_wallet_identifier(user, currency_name)

  def get_wallet_identifier(%Core.Accounts.User{id: user_id}, currency_name)
      when is_binary(currency_name) do
    {:wallet, currency_name, user_id}
  end

  def create_bank_account(name, icon, type, decimal_scale, label_bundle) do
    Budget.BankAccountModel.create(name, icon, type, decimal_scale, label_bundle)
    |> Repo.insert!()
  end

  def create_budget(%Budget.CurrencyModel{} = currency, name, icon) do
    Budget.Model.create(currency, name, icon)
    |> Repo.insert!()
  end

  def create_budget(%Budget.CurrencyModel{} = currency, name, icon, %Accounts.User{} = owner) do
    Budget.Model.create(currency, name, icon, owner)
    |> Repo.insert!()
  end

  def create_currency_and_budget(name, icon, type, decimal_scale, label) do
    Budget.Model.create(name, icon, type, decimal_scale, label)
    |> Repo.insert!()
  end

  def move_wallet_balance(
        [_ | _] = from,
        [_ | _] = to,
        idempotence_key,
        limit
      )
      when is_integer(limit) do
    Bookkeeping.Public.get_account(from)
    |> move_wallet_balance(to, idempotence_key, limit)
  end

  def move_wallet_balance(
        nil,
        [_ | _] = _to,
        idempotence_key,
        _limit
      ),
      do: raise("Unable to move balance: #{idempotence_key}")

  def move_wallet_balance(
        %{} = from_account,
        [_ | _] = to,
        idempotence_key,
        limit
      ) do
    amount = Bookkeeping.AccountModel.balance(from_account)
    move_wallet_balance(from_account, to, idempotence_key, limit, amount)
  end

  def move_wallet_balance(
        %{identifier: from},
        [_ | _] = to,
        idempotence_key,
        limit,
        amount
      )
      when amount > 0 and amount < limit do
    journal_message =
      "Moved #{amount} from account #{Identifier.to_string(from)} to account #{Identifier.to_string(to)}"

    create_payment_transaction(from, to, amount, idempotence_key, journal_message)
  end

  def move_wallet_balance(_, _, idempotence_key, limit, amount) do
    Logger.info(
      "Move wallet ballance skipped: amount=#{amount} limit=#{limit} idempotence_key=#{idempotence_key}"
    )
  end

  def wallet_is_passive?(%{
        identifier: ["wallet", _, _],
        balance_credit: balance_credit,
        balance_debit: balance_debit
      }) do
    balance_credit > 0 and balance_credit == balance_debit
  end

  def wallet_is_active?(%{identifier: ["wallet", _, _]} = wallet) do
    not wallet_is_passive?(wallet)
  end

  def create_reward(%Budget.Model{} = budget, amount, user, idempotence_key)
      when is_integer(amount) and is_binary(idempotence_key) do
    Multi.new()
    |> create_reward(budget, amount, user, idempotence_key)
    |> Repo.transaction()
  end

  def create_reward(
        multi,
        %Budget.Model{} = budget,
        amount,
        user,
        idempotence_key
      )
      when is_integer(amount) and is_binary(idempotence_key) do
    multi
    |> guard_budget_balance(budget, amount)
    |> upsert_reward(budget, amount, user, idempotence_key)
    |> make_deposit()
  end

  defp guard_budget_balance(
         multi,
         %Budget.Model{currency: %{type: :legal}} = budget,
         amount
       )
       when is_integer(amount) do
    multi
    |> Multi.run(:budget_balance, fn _, _ ->
      if Budget.Model.amount_available(budget) >= amount do
        {:ok, true}
      else
        Logger.warn("Budget has not enough funds to make reward reservation")
        {:error, :no_funding}
      end
    end)
  end

  defp guard_budget_balance(multi, _, _), do: multi

  def payout_reward(idempotence_key) when is_binary(idempotence_key) do
    case get_reward(idempotence_key, Budget.RewardModel.preload_graph(:full)) do
      nil -> Logger.warn("No reward available to payout for #{idempotence_key}")
      reward -> make_payment(reward)
    end
  end

  def multiply_rewards(currency_name, multiplier) when is_binary(currency_name) do
    currency_name
    |> Budget.Public.get_currency_by_name()
    |> multiply_rewards(multiplier)
  end

  def multiply_rewards(%Budget.CurrencyModel{} = currency, multiplier) do
    currency
    |> Budget.Public.get_by_currency!(Budget.Model.preload_graph(:full))
    |> multiply_rewards(multiplier)
  end

  def multiply_rewards(%Budget.Model{} = budget, multiplier) when multiplier > 1 do
    Budget.Public.list_wallets(budget)
    |> Enum.map(&multiply_reward(&1, budget, multiplier))
  end

  def multiply_rewards(_, multiplier), do: raise("Attempt to multiply rewards by #{multiplier}")

  defp multiply_reward(
         %Bookkeeping.AccountModel{
           balance_credit: balance_credit,
           identifier: ["wallet", currency_name, user_id]
         },
         %Budget.Model{} = budget,
         multiplier
       )
       when multiplier > 1 do
    user =
      String.to_integer(user_id)
      |> Core.Accounts.get_user!()

    reward_amount = balance_credit * (multiplier - 1)
    idempotence_key = "multiplier=#{multiplier},currency=#{currency_name},user=#{user_id}"

    Budget.Public.create_reward(budget, reward_amount, user, idempotence_key)
    Budget.Public.payout_reward(idempotence_key)
  end

  defp upsert_reward(
         multi,
         %Budget.Model{} = budget,
         amount,
         %Accounts.User{} = user,
         idempotence_key
       )
       when is_integer(amount) do
    multi
    |> Multi.run(:reward, fn _, _ ->
      case Budget.Public.get_reward(idempotence_key, Budget.RewardModel.preload_graph(:full)) do
        nil -> insert_reward(budget, amount, user, idempotence_key)
        reward -> update_reward(reward, %{amount: amount})
      end
    end)
  end

  defp insert_reward(
         %Budget.Model{} = budget,
         amount,
         %Accounts.User{} = user,
         idempotence_key
       )
       when is_integer(amount) do
    %Budget.RewardModel{}
    |> Budget.RewardModel.changeset(%{
      idempotence_key: idempotence_key,
      amount: amount,
      attempt: 0
    })
    |> put_assoc(:budget, budget)
    |> put_assoc(:user, user)
    |> put_assoc(:deposit, nil)
    |> Repo.insert()
  end

  defp update_reward(reward, %{} = attrs) do
    reward
    |> Budget.RewardModel.changeset(attrs)
    |> Repo.update()
  end

  def reward_has_outstanding_deposit?(idempotence_key) do
    from(reward in Budget.RewardModel,
      where: reward.idempotence_key == ^idempotence_key,
      where: not is_nil(reward.deposit_id),
      where: is_nil(reward.payment_id)
    )
    |> Repo.exists?()
  end

  def rollback_deposit(idempotence_key) when is_binary(idempotence_key) do
    case Budget.Public.get_reward(idempotence_key, Budget.RewardModel.preload_graph(:full)) do
      nil -> raise BudgetError, "No reward available to rollback"
      reward -> rollback_deposit(reward)
    end
  end

  def rollback_deposit(%Budget.RewardModel{} = reward) do
    Multi.new()
    |> rollback_deposit(reward)
    |> Repo.transaction()
  end

  def rollback_deposit(%Multi{} = multi, idempotence_key) when is_binary(idempotence_key) do
    case Budget.Public.get_reward(idempotence_key, Budget.RewardModel.preload_graph(:full)) do
      nil -> raise BudgetError, "No reward available to rollback"
      reward -> rollback_deposit(multi, reward)
    end
  end

  def rollback_deposit(%Multi{} = multi, reward) do
    multi
    |> revert_deposit(reward)
    |> reset_reward(reward)
  end

  defp reset_reward(multi, %Budget.RewardModel{attempt: attempt} = reward) do
    next_attempt = attempt + 1

    multi
    |> Multi.update_all(
      :reset_reward,
      fn _ ->
        from(r in Budget.RewardModel,
          where: r.id == ^reward.id,
          update: [set: [attempt: ^next_attempt, deposit_id: nil]]
        )
      end,
      []
    )
  end

  def make_test_deposit(
        %Budget.Model{
          id: budget_id,
          currency: %{
            name: currency_name,
            bank_account: %{
              id: bank_account_id,
              account: %{
                identifier: bank_account
              }
            }
          },
          fund: %{identifier: fund}
        },
        %Budget.DepositModel{amount: amount, reference: reference}
      ) do
    if Banking.Public.is_live?(currency_name) do
      raise BudgetError,
        message: "Can not deposit money from #{bank_account}. It is connected to a real bank."
    end

    amount = String.to_integer(amount)

    transaction = %{
      idempotence_key:
        "bank_account=#{bank_account_id},budget=#{budget_id},reference=#{reference}",
      journal_message: "Transfer #{amount} from #{bank_account} to #{fund}",
      lines: [
        %{
          account: bank_account,
          debit: amount
        },
        %{
          account: fund,
          credit: amount
        }
      ]
    }

    Bookkeeping.Public.enter(transaction)
  end

  def make_deposit(%Multi{} = multi) do
    multi
    |> Multi.run(:deposit, fn _, %{reward: reward} ->
      {:ok, deposit: deposit} = create_deposit_transaction(reward)
      link_deposit_transaction(reward, deposit)
    end)
  end

  defp make_payment(reward) do
    Multi.new()
    |> Multi.run(:reward, fn _, _ ->
      case create_payment_transaction(reward) do
        {:ok, %{entry: payment}} -> link_payment_transaction(reward, payment)
        error -> error
      end
    end)
    |> Repo.transaction()
  end

  defp link_deposit_transaction(reward, deposit) do
    reward
    |> Budget.RewardModel.changeset(%{})
    |> put_assoc(:deposit, deposit)
    |> Repo.update()
  end

  defp link_payment_transaction(reward, payment) do
    reward
    |> Budget.RewardModel.changeset(%{})
    |> put_assoc(:payment, payment)
    |> Repo.update()
  end

  defp create_deposit_transaction(
         %Budget.RewardModel{
           amount: amount,
           budget: %{id: budget_id, name: budget_name, currency: currency} = budget
         } = reward
       ) do
    amount_label = Budget.CurrencyModel.label(currency, :en, amount)
    journal_message = "Reserved #{amount_label} on budget #{budget_name} ##{budget_id}"

    deposit_idempotence_key = Budget.RewardModel.deposit_idempotence_key(reward)

    deposit_attrs = deposit_attrs(deposit_idempotence_key, journal_message, budget, amount)
    {:ok, %{entry: deposit}} = Bookkeeping.Public.enter(deposit_attrs)

    {:ok, deposit: deposit}
  end

  defp create_payment_transaction(%{amount: amount, payment: %{idempotence_key: idempotence_key}}) do
    Logger.warn("Reward payout already done: amount=#{amount} idempotence_key=#{idempotence_key}")
    {:error, :payment_already_available}
  end

  defp create_payment_transaction(
         %{
           deposit: nil,
           budget: %{
             fund: %{identifier: fund_id}
           }
         } = reward
       ) do
    create_payment_transaction(reward, fund_id)
  end

  defp create_payment_transaction(
         %{
           budget: %{
             reserve: %{identifier: reserve_id}
           }
         } = reward
       ) do
    create_payment_transaction(reward, reserve_id)
  end

  defp create_payment_transaction(
         %{
           idempotence_key: idempotence_key,
           amount: amount,
           user: user,
           budget: %{
             id: budget_id,
             name: budget_name,
             currency: currency
           }
         },
         from_id
       ) do
    amount_label = Budget.CurrencyModel.label(currency, :en, amount)
    journal_message = "Payout #{amount_label} on budget #{budget_name} ##{budget_id}"
    wallet_id = get_wallet_identifier(user, currency)

    payment_idempotence_key = Budget.RewardModel.payment_idempotence_key(idempotence_key)

    create_payment_transaction(
      from_id,
      wallet_id,
      amount,
      payment_idempotence_key,
      journal_message
    )
  end

  defp create_payment_transaction(from, to, amount, idempotence_key, journal_message) do
    lines = [
      %{account: from, debit: amount},
      %{account: to, credit: amount}
    ]

    payment = %{
      idempotence_key: idempotence_key,
      journal_message: journal_message,
      lines: lines
    }

    if Bookkeeping.Public.exists?(idempotence_key) do
      Logger.warn(
        "Reward payout already done: amount=#{amount} idempotence_key=#{idempotence_key}"
      )

      {:error, :payment_already_available}
    else
      result = Bookkeeping.Public.enter(payment)

      with {:error, error} <- result do
        Logger.warn("Reward payout failed: idempotence_key=#{idempotence_key}, error=#{error}")
        {:error, error}
      end
    end
  end

  defp revert_deposit(multi, reward) do
    multi
    |> Multi.run(:revert_deposit, fn _, _ ->
      revert_deposit(reward)
    end)
  end

  defp revert_deposit(%{deposit: nil}), do: {:error, :deposit_not_available}

  defp revert_deposit(%{payment: payment}) when not is_nil(payment),
    do: {:error, :payment_already_available}

  defp revert_deposit(%{deposit: deposit}), do: revert_deposit(deposit)

  defp revert_deposit(%{
         lines: lines,
         idempotence_key: idempotence_key,
         journal_message: journal_message
       })
       when is_list(lines) do
    lines =
      lines
      |> Enum.map(&revert_deposit_line(&1))

    rollback_entry = %{
      idempotence_key: "[REVERT] #{idempotence_key}",
      journal_message: "[REVERT] #{journal_message}",
      lines: lines
    }

    Bookkeeping.Public.enter(rollback_entry)
  end

  defp revert_deposit_line(
         %{account: %{identifier: account_id}, debit: debit, credit: credit} = _line
       ) do
    %{
      account: account_id,
      debit: credit,
      credit: debit
    }
  end

  defp deposit_attrs(
         idempotence_key,
         journal_message,
         %Budget.Model{fund: %{identifier: fund_id}, reserve: %{identifier: reserve_id}},
         amount
       ) do
    %{
      idempotence_key: idempotence_key,
      journal_message: journal_message,
      lines: [
        %{
          account: fund_id,
          debit: amount
        },
        %{
          account: reserve_id,
          credit: amount
        }
      ]
    }
  end

  def pending_rewards(%{id: student_id} = _student, currency) do
    from([_, _, _, u] in pending_rewards_query(currency),
      where: u.id == ^student_id
    )
    |> Repo.one!()
    |> guard_number_nil()
  end

  def pending_rewards(currency) do
    from(c in pending_rewards_query(currency))
    |> Repo.one!()
    |> guard_number_nil()
  end

  def pending_rewards_query(%{name: currency_name}), do: pending_rewards_query(currency_name)

  def pending_rewards_query(currency_name) do
    from(r in Budget.RewardModel,
      inner_join: b in Budget.Model,
      on: b.id == r.budget_id,
      inner_join: c in Budget.CurrencyModel,
      on: c.id == b.currency_id,
      inner_join: u in Accounts.User,
      on: u.id == r.user_id,
      where: c.name == ^currency_name and not is_nil(r.deposit_id) and is_nil(r.payment_id),
      select: sum(r.amount)
    )
  end

  def rewarded_amount(idempotence_key) when is_binary(idempotence_key) do
    payment_idempotence_key = Budget.RewardModel.payment_idempotence_key(idempotence_key)

    case Bookkeeping.Public.get_entry(payment_idempotence_key, [:lines]) do
      nil -> 0
      payment -> rewarded_amount(payment)
    end
  end

  def rewarded_amount(%{lines: lines}), do: rewarded_amount(lines)
  def rewarded_amount([first_line | _]), do: rewarded_amount(first_line)
  def rewarded_amount(%{debit: debit, credit: nil}), do: debit
  def rewarded_amount(%{debit: nil, credit: credit}), do: credit
  def rewarded_amount(_), do: 0

  defp guard_number_nil(nil), do: 0
  defp guard_number_nil(number), do: number
end
