defmodule Systems.Budget.Context do
  import Ecto.Query, warn: false
  import Ecto.Changeset

  require Logger

  alias Ecto.Multi
  alias Core.Repo

  alias Core.Accounts

  alias Systems.{
    Budget,
    Bookkeeping
  }

  defmodule BudgetError do
    @moduledoc false
    defexception [:message]
  end

  def list_currencies() do
    Repo.all(Budget.CurrencyModel)
  end

  def list_wallets(%Accounts.User{id: user_id}) do
    Bookkeeping.Context.list_accounts(["wallet", "#{user_id}"])
  end

  def list_wallets(%Budget.CurrencyModel{name: name}) do
    Bookkeeping.Context.list_accounts(["wallet", "#{name}"])
  end

  def list_rewards(%Accounts.User{id: user_id}, preload \\ []) do
    from(reward in Budget.RewardModel,
      where: reward.user_id == ^user_id,
      preload: ^preload
    )
    |> Repo.all()
  end

  def get!(id, preload \\ [:fund, :reserve]) do
    from(budget in Budget.Model, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_currency!(id, preload \\ []) when is_integer(id) do
    from(currency in Budget.CurrencyModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_currency_by_name!(name, preload \\ []) when is_binary(name) do
    from(currency in Budget.CurrencyModel,
      where: currency.name == ^name,
      preload: ^preload
    )
    |> Repo.one!()
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

  def get_wallet_identifier(%Core.Accounts.User{id: user_id}, %Budget.CurrencyModel{
        name: currency_name
      }) do
    {:wallet, currency_name, user_id}
  end

  def prepare(name) when is_binary(name) do
    attrs = %{
      name: name,
      fund: account_attrs(:fund, name),
      reserve: account_attrs(:reserve, name)
    }

    %Budget.Model{}
    |> Budget.Model.changeset(attrs)
    |> cast_assoc(:fund)
    |> cast_assoc(:reserve)
  end

  def create(name) when is_binary(name) do
    prepare(name)
    |> Repo.insert!()
  end

  def create_reward!(%Budget.Model{} = budget, amount, user, idempotence_key)
      when is_integer(amount) and is_binary(idempotence_key) do
    result = create_reward(budget, amount, user, idempotence_key)

    case result do
      {:ok, %{reward: reward}} -> reward
      _ -> nil
    end
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
    |> upsert_reward(budget, amount, user, idempotence_key)
    |> make_deposit()
  end

  def payout_reward(idempotence_key) when is_binary(idempotence_key) do
    case get_reward(idempotence_key, Budget.RewardModel.preload_graph(:full)) do
      nil -> raise BudgetError, "No reward available to payout"
      reward -> make_payment(reward)
    end
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
      case Budget.Context.get_reward(idempotence_key, Budget.RewardModel.preload_graph(:full)) do
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

  def rollback_reward(%Multi{} = multi, idempotence_key) when is_binary(idempotence_key) do
    case Budget.Context.get_reward(idempotence_key, Budget.RewardModel.preload_graph(:full)) do
      nil -> raise BudgetError, "No reward available to rollback"
      reward -> rollback_reward(multi, reward)
    end
  end

  def rollback_reward(%Multi{} = multi, reward) do
    multi
    |> revert_deposit(reward)
    |> reset_reward(reward)
  end

  def rollback_reward(reward) do
    Multi.new()
    |> rollback_reward(reward)
    |> Repo.transaction()
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
    {:ok, %{entry: deposit}} = Bookkeeping.Context.enter(deposit_attrs)

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

    if Bookkeeping.Context.exists?(idempotence_key) do
      Logger.warn(
        "Reward payout already done: amount=#{amount} idempotence_key=#{idempotence_key}"
      )

      {:error, :payment_already_available}
    else
      result = Bookkeeping.Context.enter(payment)

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

    Bookkeeping.Context.enter(rollback_entry)
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

  defp account_attrs(type, name) do
    %{
      identifier: Bookkeeping.Context.to_identifier({type, name}),
      balance_debit: 0,
      balance_credit: 0
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
    case Budget.Context.get_reward(idempotence_key, payment: [:lines]) do
      nil -> 0
      %{payment: payment} -> rewarded_amount(payment)
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
