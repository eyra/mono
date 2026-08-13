defmodule Systems.Fund.Public do
  use Core, :public
  import Ecto.Query, warn: false
  import Ecto.Changeset

  import Systems.Fund.Queries

  require Logger

  alias Ecto.Multi
  alias Core.Repo

  alias Frameworks.Signal
  alias Frameworks.Utility.Identifier

  alias Systems.Account
  alias Systems.Assignment

  alias Systems.Fund
  alias Systems.Bookkeeping
  alias Systems.Banking
  alias Systems.Payment

  defmodule FundError do
    @moduledoc false
    defexception [:message]
  end

  # Reward statuses at or past approval: the researcher's decision is already
  # made and the money is committed, locked on a payout, or donated. Approving
  # one again is a no-op; rejecting one is an error. Kept in one place so a new
  # terminal status can't be added to `RewardModel` and missed at one of the
  # approve/reject guards below.
  @past_approval [:approved, :paid, :pending_payout, :donating, :donated]

  def list(preload \\ []) do
    Repo.all(Fund.Model) |> Repo.preload(preload)
  end

  def list_owned(%Account.User{} = user, preload \\ []) do
    node_ids =
      auth_module().query_node_ids(
        role: :owner,
        principal: user
      )

    from(b in Fund.Model,
      where: b.auth_node_id in subquery(node_ids),
      preload: ^preload
    )
    |> Repo.all()
  end

  def list_owned_by_currency(
        %Account.User{} = user,
        %Fund.CurrencyModel{id: currency_id},
        preload \\ []
      ) do
    node_ids =
      auth_module().query_node_ids(
        role: :owner,
        principal: user
      )

    from(b in Fund.Model,
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
    Repo.all(Fund.BankAccountModel) |> Repo.preload(preload)
  end

  def list_wallets(%Account.User{id: user_id}) do
    Bookkeeping.Public.list_accounts(["wallet", "#{user_id}"])
  end

  def list_wallets(%Fund.Model{currency: currency}), do: list_wallets(currency)

  def list_wallets(%Fund.CurrencyModel{name: name}) do
    Bookkeeping.Public.list_accounts(["wallet", "#{name}"])
  end

  def list_rewards(%Account.User{id: user_id}, preload \\ []) do
    from(reward in Fund.RewardModel,
      where: reward.user_id == ^user_id,
      preload: ^preload
    )
    |> Repo.all()
  end

  @doc """
  All payouts (withdrawal requests) for a participant, newest first. Powers the
  "Uitbetalingen > Overzicht" history on the account page.
  """
  def list_payouts_for_user(%Account.User{id: user_id}) do
    from(payout in Fund.PayoutModel,
      where: payout.user_id == ^user_id,
      order_by: [desc: payout.inserted_at]
    )
    |> Repo.all()
  end

  def list_pending_approvals(%Fund.Model{} = fund, preload \\ [:user]) do
    reward_query(fund, :pending_approval)
    |> preload(^preload)
    |> Repo.all()
  end

  def has_pay_ins?(%Fund.Model{id: fund_id}) do
    from(t in Fund.TransactionModel, where: t.target_fund_id == ^fund_id)
    |> Repo.exists?()
  end

  def list_paid_rewards(%Fund.Model{} = fund, preload \\ [:user, :payment]) do
    reward_query(fund, :paid)
    |> preload(^preload)
    |> Repo.all()
  end

  @doc """
  Rewards from `:approved` onwards — the owner has confirmed the
  contribution and everything downstream (pending payout, paid).
  """
  def list_confirmed_rewards(%Fund.Model{id: fund_id}, preload \\ [:user, :payment]) do
    from(r in Fund.RewardModel,
      where: r.fund_id == ^fund_id and r.status in [:approved, :pending_payout, :paid]
    )
    |> preload(^preload)
    |> Repo.all()
  end

  def list_rejected_rewards(%Fund.Model{} = fund, preload \\ [:user]) do
    reward_query(fund, :rejected)
    |> preload(^preload)
    |> Repo.all()
  end

  def get!(id, preload \\ [:available, :pending]) when is_integer(id) do
    from(fund in Fund.Model, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_by_currency!(%Fund.CurrencyModel{id: currency_id}, preload \\ []) do
    Repo.get_by!(Fund.Model, currency_id: currency_id)
    |> Repo.preload(preload)
  end

  def get_by_name(name, preload \\ []) when is_binary(name) do
    Repo.get_by(Fund.Model, name: name)
    |> Repo.preload(preload)
  end

  def get_bank_account!(id, preload \\ []) when is_integer(id) do
    from(bank_account in Fund.BankAccountModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_currency!(id, preload \\ []) when is_integer(id) do
    from(currency in Fund.CurrencyModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_currency_by_name(name, preload \\ []) when is_binary(name) do
    Repo.get_by(Fund.CurrencyModel, name: name)
    |> Repo.preload(preload)
  end

  def get_reward!(id, preload \\ [:fund, :deposit, :payment, :user]) do
    from(reward in Fund.RewardModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_reward(idempotence_key, preload) when is_binary(idempotence_key) do
    from(reward in Fund.RewardModel,
      where: reward.idempotence_key == ^idempotence_key,
      preload: ^preload
    )
    |> Repo.one()
  end

  def get_reward(%Fund.Model{id: fund_id}, %Account.User{id: user_id}, preload \\ []) do
    from(reward in Fund.RewardModel,
      where: reward.user_id == ^user_id,
      where: reward.fund_id == ^fund_id,
      where: not (is_nil(reward.deposit_id) and is_nil(reward.payment_id)),
      preload: ^preload
    )
    |> Repo.one()
  end

  def get_wallet_identifier(%Systems.Account.User{} = user, %Fund.CurrencyModel{
        name: currency_name
      }),
      do: get_wallet_identifier(user, currency_name)

  def get_wallet_identifier(%Systems.Account.User{id: user_id}, currency_name)
      when is_binary(currency_name) do
    {:wallet, currency_name, user_id}
  end

  def create_bank_account(name, icon, type, decimal_scale, label_bundle) do
    Fund.BankAccountModel.create(name, icon, type, decimal_scale, label_bundle)
    |> Repo.insert!()
  end

  def create_fund(%Fund.CurrencyModel{} = currency, name, icon) do
    Fund.Model.create(currency, name, icon)
    |> Repo.insert!()
  end

  def create_fund(%Fund.CurrencyModel{} = currency, name, icon, %Account.User{} = owner) do
    Fund.Model.create(currency, name, icon, owner)
    |> Repo.insert!()
  end

  def create_currency_and_fund(name, icon, type, decimal_scale, label) do
    Fund.Model.create(name, icon, type, decimal_scale, label)
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

  def create_reward(%Fund.Model{}, amount, _user, idempotence_key)
      when is_integer(amount) and amount <= 0 and is_binary(idempotence_key) do
    {:error, :non_positive_amount}
  end

  def create_reward(%Fund.Model{} = fund, amount, user, idempotence_key)
      when is_integer(amount) and amount > 0 and is_binary(idempotence_key) do
    Multi.new()
    |> create_reward(fund, amount, user, idempotence_key)
    |> Repo.commit()
  end

  def create_reward(multi, %Fund.Model{}, amount, _user, idempotence_key)
      when is_integer(amount) and amount <= 0 and is_binary(idempotence_key) do
    Multi.error(multi, :create_reward, :non_positive_amount)
  end

  def create_reward(
        multi,
        %Fund.Model{} = fund,
        amount,
        user,
        idempotence_key
      )
      when is_integer(amount) and amount > 0 and is_binary(idempotence_key) do
    multi
    |> guard_fund_balance(fund, amount)
    |> upsert_reward(fund, amount, user, idempotence_key)
    |> make_deposit()
  end

  defp guard_fund_balance(
         multi,
         %Fund.Model{currency: %{type: :legal}} = fund,
         amount
       )
       when is_integer(amount) do
    Multi.run(multi, :fund_balance, fn repo, _ -> verify_fund_balance(repo, fund, amount) end)
  end

  defp guard_fund_balance(multi, %Fund.Model{currency: %{type: :virtual}}, amount)
       when is_integer(amount),
       do: multi

  defp guard_fund_balance(multi, %Fund.Model{id: fund_id}, amount) when is_integer(amount) do
    Logger.error("[Fund] refusing reservation on fund ##{fund_id} with an unresolvable currency")
    Multi.error(multi, :fund_balance, :unknown_currency)
  end

  defp verify_fund_balance(repo, %Fund.Model{available: %{id: account_id}}, amount) do
    query = from(a in Bookkeeping.AccountModel, where: a.id == ^account_id, lock: "FOR UPDATE")
    account = repo.one!(query)

    if Bookkeeping.AccountModel.balance(account) >= amount do
      {:ok, true}
    else
      Logger.warning("[Fund] fund ##{account_id} has insufficient available balance")
      {:error, :no_funding}
    end
  end

  def payout_reward(idempotence_key) when is_binary(idempotence_key) do
    case get_reward(idempotence_key, Fund.RewardModel.preload_graph(:full)) do
      nil -> Logger.warning("No reward available to payout for #{idempotence_key}")
      reward -> make_payment(reward)
    end
  end

  @doc """
  Marks a reserved reward as awaiting owner approval, inside the caller's
  Multi. Single guarded UPDATE — matches only if the reward's current status
  is `:reserved`, so it's idempotent (no-op if already past `:reserved`).
  """
  def mark_pending_approval(%Multi{} = multi, %Fund.RewardModel{id: id}) do
    query =
      from(r in Fund.RewardModel, where: r.id == ^id and r.status == ^:reserved)

    Multi.update_all(multi, :mark_pending_approval, query,
      set: [status: :pending_approval, updated_at: now()]
    )
  end

  def approve_pending_rewards(cutoff) do
    query =
      from(r in Fund.RewardModel,
        where: r.status == :pending_approval and r.updated_at < ^cutoff
      )

    query
    |> Repo.all()
    |> Repo.preload(Fund.RewardModel.preload_graph(:full))
    |> Enum.reduce([], fn reward, acc ->
      result =
        Multi.new()
        |> approve_reward(reward)
        |> Repo.commit()

      [result | acc]
    end)
  end

  @doc """
  Approves a reward and pays it out, inside the caller's Multi. The status
  flip and payment Bookkeeping entry commit atomically with whatever else
  the caller is doing.

  Idempotent on `:approved`/`:paid`. Overrides a `:rejected` reward by
  flipping it back to `:approved` and paying from `fund.available` (the
  deposit was already rolled back when the reward was rejected). The
  balance guard on the override path mirrors `guard_fund_balance` on
  reserve: only `:legal` currencies are constrained by real available
  balance; `:virtual` currencies have no such constraint.
  """
  def approve_reward(%Multi{} = multi, %Fund.RewardModel{status: status})
      when status in @past_approval,
      do: multi

  def approve_reward(%Multi{} = multi, %Fund.RewardModel{status: :rejected} = reward) do
    multi
    |> Multi.run(:approve_guard, fn repo, _ ->
      %{fund: fund, amount: amount} = Repo.preload(reward, fund: [:currency, :available])
      check_available_balance(repo, fund, amount)
    end)
    |> approve_payment_step(reward)
    |> cas_approve_step(reward, [:rejected], rejected_at: nil)
  end

  def approve_reward(%Multi{} = multi, %Fund.RewardModel{status: status} = reward)
      when status in [:reserved, :pending_approval] do
    multi
    |> approve_payment_step(reward)
    |> cas_approve_step(reward, [:reserved, :pending_approval], [])
  end

  defp check_available_balance(repo, %Fund.Model{currency: %{type: :legal}} = fund, amount) do
    case verify_fund_balance(repo, fund, amount) do
      {:ok, _} -> {:ok, :ok}
      {:error, :no_funding} -> {:error, :insufficient_fund}
    end
  end

  defp check_available_balance(_repo, %Fund.Model{currency: %{type: :virtual}}, _amount),
    do: {:ok, :ok}

  defp check_available_balance(_repo, %Fund.Model{id: fund_id}, _amount) do
    Logger.error("[Fund] refusing approval on fund ##{fund_id} with an unresolvable currency")
    {:error, :unknown_currency}
  end

  defp approve_payment_step(multi, %Fund.RewardModel{payment: %Bookkeeping.EntryModel{} = payment}) do
    Multi.run(multi, :payment, fn _, _ -> {:ok, payment} end)
  end

  defp approve_payment_step(multi, %Fund.RewardModel{} = reward) do
    Multi.run(multi, :payment, fn _, _ ->
      with {:ok, %{entry: payment}} <- create_payment_transaction(reward), do: {:ok, payment}
    end)
  end

  defp cas_approve_step(multi, %Fund.RewardModel{} = reward, from_statuses, extra_set) do
    Multi.run(multi, :reward, fn repo, %{payment: %Bookkeeping.EntryModel{id: payment_id}} ->
      cas_update(
        repo,
        reward,
        from_statuses,
        [status: :approved, payment_id: payment_id] ++ extra_set
      )
    end)
  end

  defp cas_status_step(multi, name, %Fund.RewardModel{} = reward, from_statuses, set)
       when is_list(from_statuses) and is_list(set) do
    Multi.run(multi, name, fn repo, _ -> cas_update(repo, reward, from_statuses, set) end)
  end

  # Compare-and-swap: the status precondition serializes concurrent transitions
  # so a losing writer hits 0 rows and rolls back instead of double-applying.
  defp cas_update(repo, %Fund.RewardModel{id: id}, from_statuses, set) do
    set = Keyword.put_new(set, :updated_at, now())

    query =
      from(r in Fund.RewardModel,
        where: r.id == ^id and r.status in ^from_statuses,
        select: r
      )

    case repo.update_all(query, set: set) do
      {1, [reward]} -> {:ok, reward}
      {0, _} -> {:error, :stale_reward}
    end
  end

  defp now, do: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

  @doc """
  Rejects a reward and returns the reserved money to the assignment fund,
  inside the caller's Multi. The status flip and deposit reversal commit
  atomically with whatever else the caller is doing.

  On a `:rejected` reward this is a no-op; on `:approved`/`:paid` it fails
  the surrounding transaction with `{:error, :reward_already_approved}`
  (rather than raising deep in `rollback_deposit/2`). The status flip is
  a guarded compare-and-swap, so a concurrent transition makes this a
  safe rollback.

  The reviewer's rejection reason lives on `Assignment.Participation`;
  Fund only records the outcome.
  """
  def reject_reward(%Multi{} = multi, %Fund.RewardModel{status: :rejected}), do: multi

  def reject_reward(%Multi{} = multi, %Fund.RewardModel{status: status})
      when status in @past_approval do
    Multi.run(multi, :reject_guard, fn _, _ -> {:error, :reward_already_approved} end)
  end

  def reject_reward(%Multi{} = multi, %Fund.RewardModel{} = reward) do
    multi
    |> rollback_deposit(reward)
    |> cas_status_step(:reject_status, reward, [:reserved, :pending_approval],
      status: :rejected,
      rejected_at: now()
    )
  end

  def multiply_rewards(currency_name, multiplier) when is_binary(currency_name) do
    currency_name
    |> Fund.Public.get_currency_by_name()
    |> multiply_rewards(multiplier)
  end

  def multiply_rewards(%Fund.CurrencyModel{} = currency, multiplier) do
    currency
    |> Fund.Public.get_by_currency!(Fund.Model.preload_graph(:full))
    |> multiply_rewards(multiplier)
  end

  def multiply_rewards(%Fund.Model{} = fund, multiplier) when multiplier > 1 do
    Fund.Public.list_wallets(fund)
    |> Enum.map(&multiply_reward(&1, fund, multiplier))
  end

  def multiply_rewards(_, multiplier), do: raise("Attempt to multiply rewards by #{multiplier}")

  defp multiply_reward(
         %Bookkeeping.AccountModel{
           balance_credit: balance_credit,
           identifier: ["wallet", currency_name, user_id]
         },
         %Fund.Model{} = fund,
         multiplier
       )
       when multiplier > 1 do
    user =
      String.to_integer(user_id)
      |> Systems.Account.Public.get_user!()

    reward_amount = balance_credit * (multiplier - 1)
    idempotence_key = "multiplier=#{multiplier},currency=#{currency_name},user=#{user_id}"

    Fund.Public.create_reward(fund, reward_amount, user, idempotence_key)
    Fund.Public.payout_reward(idempotence_key)
  end

  defp upsert_reward(
         multi,
         %Fund.Model{} = fund,
         amount,
         %Account.User{} = user,
         idempotence_key
       )
       when is_integer(amount) do
    multi
    |> Multi.run(:reward, fn _, _ ->
      case Fund.Public.get_reward(idempotence_key, Fund.RewardModel.preload_graph(:full)) do
        nil -> insert_reward(fund, amount, user, idempotence_key)
        reward -> update_reward(reward, %{amount: amount})
      end
    end)
  end

  defp insert_reward(
         %Fund.Model{} = fund,
         amount,
         %Account.User{} = user,
         idempotence_key
       )
       when is_integer(amount) do
    %Fund.RewardModel{}
    |> Fund.RewardModel.changeset(%{
      idempotence_key: idempotence_key,
      amount: amount,
      attempt: 0
    })
    |> put_assoc(:fund, fund)
    |> put_assoc(:user, user)
    |> put_assoc(:deposit, nil)
    |> Repo.insert()
  end

  defp update_reward(reward, %{} = attrs) do
    reward
    |> Fund.RewardModel.changeset(attrs)
    |> Repo.update()
  end

  def reward_has_outstanding_deposit?(idempotence_key) do
    from(reward in Fund.RewardModel,
      where: reward.idempotence_key == ^idempotence_key,
      where: not is_nil(reward.deposit_id),
      where: is_nil(reward.payment_id)
    )
    |> Repo.exists?()
  end

  def rollback_deposit(idempotence_key) when is_binary(idempotence_key) do
    case Fund.Public.get_reward(idempotence_key, Fund.RewardModel.preload_graph(:full)) do
      nil -> raise FundError, "No reward available to rollback"
      reward -> rollback_deposit(reward)
    end
  end

  def rollback_deposit(%Fund.RewardModel{} = reward) do
    Multi.new()
    |> rollback_deposit(reward)
    |> Repo.commit()
  end

  def rollback_deposit(%Multi{} = multi, idempotence_key) when is_binary(idempotence_key) do
    case Fund.Public.get_reward(idempotence_key, Fund.RewardModel.preload_graph(:full)) do
      nil -> raise FundError, "No reward available to rollback"
      reward -> rollback_deposit(multi, reward)
    end
  end

  def rollback_deposit(%Multi{} = multi, reward) do
    multi
    |> revert_deposit(reward)
    |> reset_reward(reward)
  end

  defp reset_reward(multi, %Fund.RewardModel{attempt: attempt} = reward) do
    next_attempt = attempt + 1

    multi
    |> Multi.update_all(
      :reset_reward,
      fn _ ->
        from(r in Fund.RewardModel,
          where: r.id == ^reward.id,
          update: [set: [attempt: ^next_attempt, deposit_id: nil]]
        )
      end,
      []
    )
  end

  def make_test_deposit(
        %Fund.Model{
          id: fund_id,
          currency: %{
            name: currency_name,
            bank_account: %{
              id: bank_account_id,
              account: %{
                identifier: bank_account
              }
            }
          },
          available: %{identifier: fund_account}
        },
        %Fund.DepositModel{amount: amount, reference: reference}
      ) do
    if Banking.Public.is_live?(currency_name) do
      raise FundError,
        message: "Can not deposit money from #{bank_account}. It is connected to a real bank."
    end

    amount = String.to_integer(amount)

    transaction = %{
      idempotence_key: "bank_account=#{bank_account_id},fund=#{fund_id},reference=#{reference}",
      journal_message: "Transfer #{amount} from #{bank_account} to #{fund_account}",
      lines: [
        %{
          account: bank_account,
          debit: amount
        },
        %{
          account: fund_account,
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
    |> Repo.commit()
  end

  defp link_deposit_transaction(reward, deposit) do
    reward
    |> Fund.RewardModel.changeset(%{})
    |> put_assoc(:deposit, deposit)
    |> Repo.update()
  end

  defp link_payment_transaction(reward, payment) do
    reward
    |> Fund.RewardModel.changeset(%{})
    |> put_assoc(:payment, payment)
    |> Repo.update()
  end

  defp create_deposit_transaction(
         %Fund.RewardModel{
           amount: amount,
           fund: %{id: fund_id, name: fund_name, currency: currency} = the_fund
         } = reward
       ) do
    amount_label = Fund.CurrencyModel.label(currency, :en, amount)
    journal_message = "Reserved #{amount_label} on fund #{fund_name} ##{fund_id}"

    deposit_idempotence_key = Fund.RewardModel.deposit_idempotence_key(reward)

    deposit_attrs = deposit_attrs(deposit_idempotence_key, journal_message, the_fund, amount)
    {:ok, %{entry: deposit}} = Bookkeeping.Public.enter(deposit_attrs)

    {:ok, deposit: deposit}
  end

  defp create_payment_transaction(%{amount: amount, payment: %{idempotence_key: idempotence_key}}) do
    Logger.warning(
      "Reward payout already done: amount=#{amount} idempotence_key=#{idempotence_key}"
    )

    {:error, :payment_already_available}
  end

  defp create_payment_transaction(
         %{
           deposit: nil,
           fund: %{
             available: %{identifier: fund_id}
           }
         } = reward
       ) do
    create_payment_transaction(reward, fund_id)
  end

  defp create_payment_transaction(
         %{
           fund: %{
             pending: %{identifier: reserve_id}
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
           fund: %{
             id: fund_id,
             name: fund_name,
             currency: currency
           }
         },
         from_id
       ) do
    amount_label = Fund.CurrencyModel.label(currency, :en, amount)
    journal_message = "Payout #{amount_label} on fund #{fund_name} ##{fund_id}"
    wallet_id = get_wallet_identifier(user, currency)

    payment_idempotence_key = Fund.RewardModel.payment_idempotence_key(idempotence_key)

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

    case Bookkeeping.Public.get_entry(idempotence_key) do
      %Bookkeeping.EntryModel{} = existing ->
        Logger.info(
          "Reward payout already booked, adopting existing entry: idempotence_key=#{idempotence_key}"
        )

        {:ok, %{entry: existing}}

      nil ->
        with {:error, error} <- Bookkeeping.Public.enter(payment) do
          Logger.warning(
            "Reward payout failed: idempotence_key=#{idempotence_key}, error=#{error}"
          )

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
         %Fund.Model{available: %{identifier: fund_id}, pending: %{identifier: reserve_id}},
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
    from(r in Fund.RewardModel,
      inner_join: b in Fund.Model,
      on: b.id == r.fund_id,
      inner_join: c in Fund.CurrencyModel,
      on: c.id == b.currency_id,
      inner_join: u in Account.User,
      on: u.id == r.user_id,
      where: c.name == ^currency_name and not is_nil(r.deposit_id) and is_nil(r.payment_id),
      select: sum(r.amount)
    )
  end

  @doc """
  Per-status reward totals (in cents) for the home rewards-summary card.
  """
  def summarize_rewards(%Account.User{id: user_id}, currency) do
    totals =
      reward_query_in_currency(user_id, currency)
      |> group_by([reward: r], r.status)
      |> select([reward: r], {r.status, sum(r.amount)})
      |> Repo.all()
      |> Enum.into(%{})

    amount = fn status -> Map.get(totals, status) || 0 end

    %{
      pending_cents: amount.(:reserved) + amount.(:pending_approval),
      approved_cents: amount.(:approved),
      pending_payout_cents: amount.(:pending_payout),
      paid_out_cents: amount.(:paid),
      rejected_cents: amount.(:rejected),
      donating_cents: amount.(:donating),
      donated_cents: amount.(:donated)
    }
  end

  @payout_threshold_cents 500

  @doc """
  Minimum approved balance (in cents) required to request a payout — €5.
  """
  def payout_threshold_cents, do: @payout_threshold_cents

  @doc """
  Requests a payout for all of the participant's `:approved` rewards: locks
  them, then transfers and withdraws via the payment provider. Returns `{:ok, result}` or
  `{:error, reason}`.
  """
  def request_payout(%Account.User{} = user, currency) do
    # Reload: the caller may hold a struct from before prepare_payout/2 set merchant_uid.
    user |> Repo.reload!() |> resume_or_start_payout(currency)
  end

  defp resume_or_start_payout(%Account.User{merchant_uid: nil}, _currency),
    do: {:error, :no_merchant}

  # Resume an unresolved payout rather than start a fresh one: a new payout only
  # sees :approved rewards, so it would strand the ones locked on the old one.
  defp resume_or_start_payout(%Account.User{id: user_id, merchant_uid: merchant_uid}, currency) do
    case find_unresolved_payout(user_id) do
      %Fund.PayoutModel{} = payout -> resume_payout(payout)
      nil -> start_new_payout(user_id, merchant_uid, currency)
    end
  end

  defp start_new_payout(user_id, merchant_uid, currency) do
    approved = list_approved_rewards(user_id, currency)
    total = Enum.reduce(approved, 0, fn %{amount: amount}, acc -> acc + amount end)

    if total < @payout_threshold_cents do
      {:error, {:below_threshold, total}}
    else
      do_request_payout(user_id, merchant_uid, approved, total)
    end
  end

  # A :failed payout is still unresolved only if its funds moved; without a
  # commit it reverted its own lock and its rewards are back in :approved.
  defp find_unresolved_payout(user_id) do
    from(p in Fund.PayoutModel,
      where: p.user_id == ^user_id,
      where: p.status == :pending or (p.status == :failed and not is_nil(p.funds_committed_at)),
      order_by: [asc: p.inserted_at],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  The participant's payout situation for display, so the home card can surface a
  stranded payout the reward-status columns don't show:

    * `:none`        — no unresolved payout; the normal "Uitbetalen" flow applies.
    * `:in_progress` — issued and awaiting the bank; nothing for the user to do.
    * `:retryable`   — stranded but recoverable; a "retry" resumes it.
    * `:manual`      — an unconfirmed transfer that only support can resolve.
  """
  @spec payout_status(Account.User.t()) :: :none | :in_progress | :retryable | :manual
  def payout_status(%Account.User{id: user_id}) do
    case find_unresolved_payout(user_id) do
      nil -> :none
      payout -> display_status(Fund.PayoutModel.phase(payout))
    end
  end

  defp display_status(:awaiting_provider), do: :in_progress

  defp display_status(phase) when phase in [:awaiting_withdrawal, :withdrawal_retryable],
    do: :retryable

  defp display_status(:awaiting_transfer), do: :manual

  @doc """
  Pure pre-flight threshold check (no side effects), used by `prepare_payout/2`.
  """
  def payout_eligibility(%Account.User{id: user_id}, currency) do
    total =
      list_approved_rewards(user_id, currency)
      |> Enum.reduce(0, fn %{amount: amount}, acc -> acc + amount end)

    if total < @payout_threshold_cents do
      {:error, {:below_threshold, total}}
    else
      :ok
    end
  end

  @doc """
  Side-effecting pre-handoff check (UC-OPP-06.A1): ensures merchant + bank
  account exist, then reports payout readiness via `payout_ready_for/1`.
  """
  def prepare_payout(%Account.User{} = user, currency) do
    with :ok <- payout_eligibility(user, currency),
         {:ok, {_user, merchant}} <- Payment.Public.ensure_merchant_for(user),
         {:ok, bank_account} <- Payment.Public.ensure_bank_account_for(merchant.uid) do
      payout_ready_for(bank_account)
    end
  end

  # A verified bank account (OPP Level 200) is sufficient for participant payouts;
  # merchant identity-KYC (Level 400) is never required. Ready iff the bank
  # account is approved, so a withdrawal never fires against an unapproved account.
  defp payout_ready_for(%{status: :verified}), do: :ok

  # `:new` is the only status where the participant still has something to do —
  # complete the provider's hosted iDEAL flow at the verification URL. Any other
  # non-verified status (`:pending`, etc.) means the provider is reviewing and the
  # participant just needs to wait, even if a stale verification_url is still
  # returned — so match on status first, URL second.
  defp payout_ready_for(%{status: :new, verification_url: verification_url})
       when is_binary(verification_url) and verification_url != "",
       do: {:error, {:kyc_required, :bank, verification_url}}

  defp payout_ready_for(%{status: status})
       when is_atom(status) and not is_nil(status) and status != :new,
       do: {:error, :awaiting_verification}

  defp payout_ready_for(_bank_account), do: {:error, :kyc_unavailable}

  @doc """
  Read-only KYC/bank-account verification status for the account page's
  "Bankrekening" section. Never creates a merchant: a user without a
  `merchant_uid` (never started a payout) is simply `:not_verified`.

  Unlike `payout_ready_for/2` (which collapses "no redirect URL yet" into
  `:kyc_unavailable`), this distinguishes `:pending` — a bank account submitted
  to OPP that is still being reviewed — so the UI can show "Wordt geverifiëerd".
  """
  @spec verification_status(Account.User.t()) :: :not_verified | :pending | :verified
  def verification_status(%Account.User{merchant_uid: nil}), do: :not_verified

  def verification_status(%Account.User{merchant_uid: merchant_uid}) do
    case Payment.Public.list_bank_accounts(merchant_uid) do
      {:ok, accounts} ->
        accounts
        |> Enum.find(&(&1.status != :rejected))
        |> bank_account_status()

      {:error, _} ->
        :not_verified
    end
  end

  # The normalized `status` is authoritative for the display state. A bank account
  # under review (`:pending`) can still carry a `verification_url`, so status must
  # be matched before any URL fallback — otherwise a pending account is mislabeled
  # "not verified". `:new` means the participant still has to complete verification
  # (the "Toevoegen" iDEAL flow); anything else non-verified is being reviewed.
  defp bank_account_status(%{status: :verified}), do: :verified
  defp bank_account_status(%{status: :new}), do: :not_verified
  defp bank_account_status(%{status: status}) when is_atom(status), do: :pending
  defp bank_account_status(_bank_account), do: :not_verified

  @doc """
  Onboarding entry point for the "Toevoegen" action: ensures the merchant + bank
  account exist (creating them if needed) and reports how to continue. Independent
  of payout-threshold eligibility — a participant can verify their bank before
  earning anything.

  Returns `{:bank, verification_url}` (drive the seamless iDEAL picker),
  `:verified`, or `{:error, reason}`.

  The arity-2 form pushes the given phone to the merchant — used when collecting
  it in the phone form. The arity-1 form is for the already-on-file case and does
  not re-push (the phone was pushed to OPP when first collected).
  """
  @spec start_bank_verification(Account.User.t()) ::
          {:bank, String.t()} | :verified | {:error, term()}
  def start_bank_verification(%Account.User{} = user) do
    start_bank_verification(user, nil)
  end

  @spec start_bank_verification(Account.User.t(), String.t() | nil) ::
          {:bank, String.t()} | :verified | {:error, term()}
  def start_bank_verification(%Account.User{} = user, phone) do
    with {:ok, {_user, merchant}} <- Payment.Public.ensure_merchant_for(user, phone),
         {:ok, bank_account} <- Payment.Public.ensure_bank_account_for(merchant.uid) do
      bank_handoff(merchant, bank_account)
    end
  end

  # A verified bank account is all we need; we never hand off to OPP's hosted
  # merchant-overview screen. Approved → done; otherwise drive the iDEAL flow.
  defp bank_handoff(_merchant, %{status: :verified}), do: :verified

  defp bank_handoff(_merchant, %{verification_url: verification_url})
       when is_binary(verification_url) and verification_url != "",
       do: {:bank, verification_url}

  defp bank_handoff(_merchant, _bank_account), do: :verified

  # Re-check readiness at confirm time against fresh OPP state (TOCTOU guard).
  # Only the bank account gates the payout, so we re-fetch just that.
  defp recheck_payout_ready(merchant_uid) do
    case Payment.Public.ensure_bank_account_for(merchant_uid) do
      {:ok, bank_account} -> payout_ready_for(bank_account)
      {:error, _} = error -> error
    end
  end

  defp do_request_payout(user_id, merchant_uid, approved, total) do
    case recheck_payout_ready(merchant_uid) do
      :ok -> lock_and_withdraw(user_id, merchant_uid, approved, total)
      {:error, _} = error -> error
    end
  end

  defp lock_and_withdraw(user_id, merchant_uid, approved, total) do
    reward_ids = Enum.map(approved, fn %{id: id} -> id end)

    with platform_uid when not is_nil(platform_uid) <- Payment.Public.platform_merchant_uid(),
         {:ok, payout} <- lock_for_payout(user_id, reward_ids, total) do
      withdraw_for_payout(payout, platform_uid, merchant_uid, total, reward_ids)
    else
      nil -> {:error, :no_platform_merchant}
      {:error, _reason} -> {:error, :lock_failed}
    end
  end

  # Per-leg idempotence keys so retries never double-move money.
  defp withdraw_for_payout(payout, platform_uid, merchant_uid, total, reward_ids) do
    case Payment.Public.transfer_to_merchant(
           platform_uid,
           merchant_uid,
           total,
           Fund.PayoutModel.transfer_key(payout)
         ) do
      {:ok, transfer} ->
        payout
        |> commit_funds(transfer)
        |> Fund.PayoutWithdrawal.issue(merchant_uid, total)

      {:error, %Payment.Error{} = error} ->
        handle_transfer_error(error, reward_ids)
    end
  end

  # Reverting after the money moved lets a later payout re-lock and re-charge, so
  # only revert on a definitive rejection; leave an uncertain outcome to reconciliation.
  defp handle_transfer_error(%Payment.Error{} = error, reward_ids) do
    if transfer_rejected?(error) do
      revert_payout_lock(reward_ids, "transfer_rejected: #{inspect(error)}")
      {:error, {:opp_failed, error}}
    else
      Logger.error(
        "[Fund] transfer outcome uncertain, leaving payout :pending for reconciliation: " <>
          inspect(error)
      )

      {:error, {:opp_uncertain, error}}
    end
  end

  defp transfer_rejected?(%Payment.Error{code: :api_error, details: %{status: status}})
       when is_integer(status) and status >= 400 and status < 500,
       do: true

  defp transfer_rejected?(%Payment.Error{}), do: false

  defp commit_funds(%Fund.PayoutModel{} = payout, %{uid: transfer_uid}) do
    payout
    |> Fund.PayoutModel.changeset(%{transfer_uid: transfer_uid, funds_committed_at: now()})
    |> Repo.update()
    |> case do
      {:ok, payout} ->
        payout

      {:error, _changeset} ->
        Logger.error(
          "[Fund] transfer #{transfer_uid} accepted but not persisted for payout " <>
            "##{payout.id}; the funds are committed and the uid is lost"
        )

        payout
    end
  end

  defp lock_for_payout(user_id, reward_ids, total) do
    Multi.new()
    |> Multi.insert(:payout, new_payout_changeset(user_id, total))
    |> Multi.run(:lock_rewards, fn _repo, %{payout: %{id: payout_id}} ->
      lock_approved_rewards(reward_ids, payout_id)
    end)
    |> Repo.commit()
    |> case do
      {:ok, %{payout: payout}} -> {:ok, payout}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  defp new_payout_changeset(user_id, total) do
    Fund.PayoutModel.changeset(%Fund.PayoutModel{}, %{
      user_id: user_id,
      amount_cents: total,
      status: :pending
    })
  end

  # CAS on :approved — a concurrent payout leaves us short of the count, so we
  # roll back rather than fire a duplicate OPP payout.
  defp lock_approved_rewards(reward_ids, payout_id) do
    {count, _} =
      from(r in Fund.RewardModel, where: r.id in ^reward_ids and r.status == :approved)
      |> Repo.update_all(set: [status: :pending_payout, payout_id: payout_id, updated_at: now()])

    if count == length(reward_ids), do: {:ok, count}, else: {:error, :stale_rewards}
  end

  defp revert_payout_lock(reward_ids, failure_reason) do
    Multi.new()
    |> Multi.run(:payout, fn _repo, _changes -> fail_batch_payout(reward_ids, failure_reason) end)
    |> Multi.update_all(
      :rewards,
      from(r in Fund.RewardModel, where: r.id in ^reward_ids),
      set: [status: :approved, payout_id: nil, updated_at: now()]
    )
    |> Repo.commit()
    |> case do
      {:ok, _changes} ->
        :ok

      {:error, step, reason, _changes} ->
        Logger.error(
          "[Fund] failed to revert payout lock for rewards #{inspect(reward_ids)} at " <>
            "#{step} (#{failure_reason}); they remain :pending_payout: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  # Rewards in a batch share one payout_id; mark that payout :failed.
  defp fail_batch_payout(reward_ids, failure_reason) do
    case batch_payout_id(reward_ids) do
      nil ->
        {:ok, nil}

      payout_id ->
        Repo.get!(Fund.PayoutModel, payout_id)
        |> Fund.PayoutModel.changeset(%{status: :failed, failure_reason: failure_reason})
        |> Repo.update()
    end
  end

  defp batch_payout_id(reward_ids) do
    Repo.one(
      from(r in Fund.RewardModel,
        where: r.id in ^reward_ids and not is_nil(r.payout_id),
        select: r.payout_id,
        limit: 1
      )
    )
  end

  defp list_approved_rewards(user_id, currency) do
    reward_query_in_currency(user_id, currency)
    |> where([reward: r], r.status == :approved)
    |> Repo.all()
  end

  @doc """
  Donates every `:approved` reward the participant holds in `currency` to Eyra,
  waiving the right to have them paid out (UC-OPP-07).

  The money already sits on the platform merchant, so unlike a payout there is
  nothing to transfer to the participant and nothing to withdraw: a single
  provider charge settles it as the operator's own. Rewards go
  `:approved -> :donating -> :donated`, locked the same way a payout locks them.

  No threshold and no KYC. `@payout_threshold_cents` exists because withdrawals
  cost money; a donation has no such floor, so donating €0.50 is fine.

  Returns `{:ok, donation}`, or:
    * `{:error, :nothing_to_donate}` — no approved rewards in this currency
    * `{:error, :no_platform_merchant}` — `OPP_MERCHANT_UID` unset
    * `{:error, :lock_failed}` — a concurrent payout or donation took the rewards
    * `{:error, {:opp_failed, error}}` — definitively rejected, lock released
    * `{:error, {:opp_uncertain, error}}` — outcome unknown; the rewards stay
      `:donating` for manual resolution (see `Fund.DonationModel`)
  """
  def request_donation(%Account.User{id: user_id}, currency) do
    approved = list_approved_rewards(user_id, currency)
    total = Enum.reduce(approved, 0, fn %{amount: amount}, acc -> acc + amount end)

    if total > 0 do
      do_request_donation(user_id, Enum.map(approved, fn %{id: id} -> id end), total)
    else
      {:error, :nothing_to_donate}
    end
  end

  # Read the platform merchant before locking, so a misconfigured env never
  # strands rewards in :donating.
  defp do_request_donation(user_id, reward_ids, total) do
    with platform_uid when not is_nil(platform_uid) <- Payment.Public.platform_merchant_uid(),
         {:ok, donation} <- lock_for_donation(user_id, reward_ids, total) do
      charge_donation(donation, platform_uid, total, reward_ids)
    else
      nil -> {:error, :no_platform_merchant}
      {:error, _reason} -> {:error, :lock_failed}
    end
  end

  defp charge_donation(%Fund.DonationModel{} = donation, platform_uid, total, reward_ids) do
    case Payment.Public.charge_to_partner(
           platform_uid,
           total,
           Fund.DonationModel.charge_key(donation)
         ) do
      {:ok, %{uid: charge_uid}} ->
        finalize_donation(donation, charge_uid)

      {:error, %Payment.Error{} = error} ->
        handle_charge_error(error, donation, reward_ids)
    end
  end

  # Same policy as the payout's transfer leg: only a definitive rejection
  # releases the lock. An uncertain outcome leaves the rewards :donating —
  # charges cannot be listed at OPP and there is no charge webhook, so a stuck
  # donation is resolved by hand. The log carries donation=<uid>, which is also
  # what the provider received as metadata.reference.
  defp handle_charge_error(
         %Payment.Error{} = error,
         %Fund.DonationModel{uid: uid} = donation,
         reward_ids
       ) do
    if transfer_rejected?(error) do
      revert_donation_lock(donation, reward_ids, "charge_rejected: #{inspect(error)}")
      {:error, {:opp_failed, error}}
    else
      Logger.error(
        "[Fund] donation charge outcome uncertain, leaving donation=#{uid} :pending " <>
          "for manual review: #{inspect(error)}"
      )

      {:error, {:opp_uncertain, error}}
    end
  end

  defp lock_for_donation(user_id, reward_ids, total) do
    Multi.new()
    |> Multi.insert(:donation, new_donation_changeset(user_id, total))
    |> Multi.run(:lock_rewards, fn _repo, %{donation: %{id: donation_id}} ->
      lock_approved_rewards_for_donation(reward_ids, donation_id)
    end)
    |> Repo.commit()
    |> case do
      {:ok, %{donation: donation}} -> {:ok, donation}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  defp new_donation_changeset(user_id, total) do
    Fund.DonationModel.changeset(%Fund.DonationModel{}, %{
      user_id: user_id,
      amount_cents: total,
      status: :pending
    })
  end

  # CAS on :approved — a concurrent payout or donation leaves us short of the
  # count, so we roll back rather than charge for money we never locked.
  defp lock_approved_rewards_for_donation(reward_ids, donation_id) do
    {count, _} =
      from(r in Fund.RewardModel, where: r.id in ^reward_ids and r.status == :approved)
      |> Repo.update_all(set: [status: :donating, donation_id: donation_id, updated_at: now()])

    if count == length(reward_ids), do: {:ok, count}, else: {:error, :stale_rewards}
  end

  defp finalize_donation(%Fund.DonationModel{id: donation_id} = donation, charge_uid) do
    Multi.new()
    |> Multi.update(
      :donation,
      Fund.DonationModel.changeset(donation, %{status: :completed, charge_uid: charge_uid})
    )
    |> Multi.update_all(
      :rewards,
      from(r in Fund.RewardModel,
        where: r.donation_id == ^donation_id and r.status == :donating
      ),
      set: [status: :donated, updated_at: now()]
    )
    |> Repo.commit()
    |> case do
      {:ok, %{donation: donation}} -> notify_rewards_summary(donation)
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  defp revert_donation_lock(%Fund.DonationModel{} = donation, reward_ids, failure_reason) do
    Multi.new()
    |> Multi.update(
      :donation,
      Fund.DonationModel.changeset(donation, %{status: :failed, failure_reason: failure_reason})
    )
    |> Multi.update_all(
      :rewards,
      from(r in Fund.RewardModel, where: r.id in ^reward_ids and r.status == :donating),
      set: [status: :approved, donation_id: nil, updated_at: now()]
    )
    |> Repo.commit()
    |> case do
      {:ok, _changes} ->
        :ok

      {:error, step, reason, _changes} ->
        Logger.error(
          "[Fund] failed to revert donation lock for rewards #{inspect(reward_ids)} at " <>
            "#{step} (#{failure_reason}); they remain :donating: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  @doc """
  Applies a provider withdrawal status change to the linked payout and its rewards.
  Idempotent: terminal payouts short-circuit. Returns `{:ok, payout}` when a
  payout was found, `{:ok, nil}` when none matched the uid, or `{:error, reason}`.
  """
  def apply_withdrawal_status(provider_uid, %{status: status, raw_status: raw_status})
      when is_binary(provider_uid) and is_atom(status) and is_binary(raw_status) do
    case Repo.get_by(Fund.PayoutModel, provider_uid: provider_uid) do
      nil ->
        Logger.warning("[Fund] withdrawal #{provider_uid} not linked to any Payout — ignoring")

        {:ok, nil}

      %Fund.PayoutModel{status: payout_status} = payout
      when payout_status in [:completed, :failed] ->
        # Already terminal; tolerate the provider's webhook retries.
        {:ok, payout}

      %Fund.PayoutModel{} = payout ->
        apply_status(payout, status, raw_status)
    end
  end

  defp apply_status(%Fund.PayoutModel{} = payout, :completed, _raw_status) do
    finalize_payout(payout, :completed, :paid, nil)
  end

  defp apply_status(%Fund.PayoutModel{} = payout, :failed, raw_status) do
    # Transfer already moved funds — don't revert to :approved (would re-pay). SF-OPP-02 reconciles.
    fail_payout(payout, "provider_status: #{raw_status}")
  end

  defp apply_status(%Fund.PayoutModel{provider_uid: uid} = payout, :pending, raw_status) do
    Logger.info("[Fund] withdrawal #{uid} provider status=#{raw_status} — no local transition")

    {:ok, payout}
  end

  defp finalize_payout(
         %Fund.PayoutModel{id: payout_id} = payout,
         payout_status,
         reward_status,
         failure_reason
       ) do
    Multi.new()
    |> Multi.update(
      :payout,
      Fund.PayoutModel.changeset(payout, %{status: payout_status, failure_reason: failure_reason})
    )
    |> Multi.update_all(
      :rewards,
      from(r in Fund.RewardModel,
        where: r.payout_id == ^payout_id and r.status == :pending_payout
      ),
      set: [status: reward_status, updated_at: now()]
    )
    |> Repo.commit()
    |> case do
      {:ok, %{payout: payout}} -> notify_rewards_summary(payout)
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  defp fail_payout(%Fund.PayoutModel{} = payout, failure_reason) do
    case payout
         |> Fund.PayoutModel.changeset(%{status: :failed, failure_reason: failure_reason})
         |> Repo.update() do
      {:ok, payout} -> notify_rewards_summary(payout)
      {:error, _changeset} = error -> error
    end
  end

  defp notify_rewards_summary(%Fund.PayoutModel{user_id: user_id} = payout) do
    Signal.Public.dispatch({:fund_rewards_summary, :updated}, %{user_id: user_id})
    {:ok, payout}
  end

  defp notify_rewards_summary(%Fund.DonationModel{user_id: user_id} = donation) do
    Signal.Public.dispatch({:fund_rewards_summary, :updated}, %{user_id: user_id})
    {:ok, donation}
  end

  @doc """
  Drives a stranded payout forward, without ever re-moving money.
  See `Systems.Fund.PayoutWithdrawal.resume/1`.
  """
  def resume_payout(%Fund.PayoutModel{} = payout), do: Fund.PayoutWithdrawal.resume(payout)

  @doc """
  Reconciles `:pending` payouts against the payment provider.
  See `Systems.Fund.PayoutReconciliation`.
  """
  def reconcile_pending_payouts(opts, state), do: Fund.PayoutReconciliation.run(opts, state)

  @doc """
  Flags provider withdrawals and transfers that have no local payout row.
  See `Systems.Fund.PayoutOrphanReconciliation`.
  """
  def reconcile_orphaned_payouts(opts, state),
    do: Fund.PayoutOrphanReconciliation.run(opts, state)

  def rewarded_amount(idempotence_key) when is_binary(idempotence_key) do
    payment_idempotence_key = Fund.RewardModel.payment_idempotence_key(idempotence_key)

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

  # --- Pay-in mechanics (merged from Systems.Budget.Public) ---

  def list_transactions_by_fund(%Fund.Model{id: fund_id}) do
    from(t in Fund.TransactionModel,
      where: t.target_fund_id == ^fund_id,
      order_by: [desc: t.inserted_at]
    )
    |> Repo.all()
  end

  def get_transaction_by_provider_uid!(provider_uid) do
    Repo.get_by!(Fund.TransactionModel, transaction_id: provider_uid)
  end

  # --- Pay-in creation ---

  @doc """
  Creates a pending transaction and initiates payment with the payment provider.
  Lazily creates an OPP merchant for the user if needed.
  Returns {:ok, %{transaction: transaction, payment_url: url}} or {:error, reason}.
  """
  def create_pay_in(
        %Assignment.Model{info: info} = assignment,
        %Account.User{} = user,
        attrs
      )
      when is_map(attrs) do
    changeset =
      %Fund.PayInRequestModel{}
      |> Fund.PayInRequestModel.changeset(with_info_defaults(info, attrs))
      |> Fund.PayInRequestModel.validate()

    with {:ok, request} <- Ecto.Changeset.apply_action(changeset, :insert),
         {:ok, updated_info} <- persist_pay_in_info(info, request) do
      do_create_pay_in(%{assignment | info: updated_info}, user, request.subject_count)
    end
  end

  # Fields the researcher can't edit (e.g. reward when locked because
  # transactions already exist) fall back to the persisted assignment info.
  defp with_info_defaults(
         %Assignment.InfoModel{subject_reward: reward, aim_of_study: aim},
         attrs
       ) do
    attrs
    |> Map.put_new("subject_reward", reward)
    |> Map.put_new("aim_of_study", aim)
  end

  defp persist_pay_in_info(%Assignment.InfoModel{} = info, %Fund.PayInRequestModel{
         subject_reward: reward,
         aim_of_study: aim
       }) do
    info
    |> Assignment.InfoModel.changeset(:auto_save, %{
      "subject_reward" => reward,
      "aim_of_study" => aim
    })
    |> then(&Core.Persister.save(&1.data, &1))
  end

  defp do_create_pay_in(
         %Assignment.Model{info: %{subject_reward: subject_reward}, fund: fund} = assignment,
         %Account.User{id: user_id} = user,
         subject_count
       ) do
    reward_per_participant = subject_reward || 0
    base_amount = subject_count * reward_per_participant
    partner_fee = Payment.Public.partner_fee_amount(base_amount)
    total_amount = base_amount + partner_fee

    if total_amount > 0 do
      create_paid_pay_in(assignment, user, subject_count, total_amount, partner_fee)
    else
      create_free_pay_in(fund, user_id, subject_count)
    end
  end

  defp create_paid_pay_in(
         %Assignment.Model{
           info: %{
             subject_reward: subject_reward,
             title: title,
             subtitle: subtitle,
             aim_of_study: aim_of_study
           },
           fund: fund
         } = assignment,
         %Account.User{id: user_id} = user,
         subject_count,
         total_amount,
         partner_fee
       ) do
    merchant_uid = pay_in_merchant_uid(user)
    reward_per_participant = subject_reward || 0
    currency = get_currency(fund)
    idempotence_key = "pay_in:fund=#{fund.id}:#{Ecto.UUID.generate()}"
    invoice_id = generate_invoice_id()

    description = %Payment.Transaction.Description{
      platform: "Next",
      assignment: title || "Untitled",
      participant_count: subject_count,
      amount_per_participant: reward_per_participant
    }

    metadata = %Payment.Transaction.Metadata{
      contact_person: "Researcher ##{user_id}",
      study_title: title || "Untitled",
      study_goal: subtitle || "",
      aim_of_study: aim_of_study,
      participant_count: subject_count,
      amount_per_participant: reward_per_participant
    }

    return_url = return_url(assignment)

    opts = [return_url: return_url]
    opts = if partner_fee > 0, do: Keyword.put(opts, :partner_fee, partner_fee), else: opts

    request = %Payment.Transaction.Request{
      merchant_uid: merchant_uid,
      total_amount: total_amount,
      currency: currency,
      invoice_id: invoice_id,
      idempotence_key: idempotence_key,
      description: description,
      metadata: metadata,
      opts: opts
    }

    with {:ok, provider_result} <- Payment.Public.create_transaction(request),
         {:ok, transaction} <-
           %Fund.TransactionModel{}
           |> Fund.TransactionModel.changeset(%{
             transaction_id: provider_result.uid,
             status: :pending,
             idempotence_key: idempotence_key,
             invoice_id: invoice_id,
             subject_count: subject_count,
             total_amount: total_amount
           })
           |> Ecto.Changeset.put_change(:user_id, user_id)
           |> Ecto.Changeset.put_change(:target_fund_id, fund.id)
           |> Repo.insert() do
      {:ok, %{transaction: transaction, payment_url: provider_result.payment_url}}
    end
  end

  # Pay-ins fund the platform merchant (the float for payout charges); fall back
  # to the user's own merchant only when no platform merchant is configured.
  defp pay_in_merchant_uid(user) do
    case Payment.Public.platform_merchant_uid() do
      nil ->
        {:ok, {_user, %{uid: uid}}} = Payment.Public.ensure_merchant_for(user)
        uid

      uid ->
        uid
    end
  end

  defp create_free_pay_in(%Fund.Model{id: fund_id}, user_id, subject_count) do
    idempotence_key = "pay_in:fund=#{fund_id}:#{Ecto.UUID.generate()}"
    invoice_id = generate_invoice_id()

    with {:ok, transaction} <-
           %Fund.TransactionModel{}
           |> Fund.TransactionModel.changeset(%{
             transaction_id: "free_#{Ecto.UUID.generate()}",
             status: :completed,
             idempotence_key: idempotence_key,
             invoice_id: invoice_id,
             subject_count: subject_count,
             total_amount: 0
           })
           |> Ecto.Changeset.put_change(:user_id, user_id)
           |> Ecto.Changeset.put_change(:target_fund_id, fund_id)
           |> Repo.insert() do
      increment_subject_count(fund_id, subject_count)
      {:ok, %{transaction: transaction, payment_url: nil}}
    end
  end

  # --- Transaction completion ---

  @doc """
  Completes a transaction after successful payment.
  In one atomic Multi:
  1. Update transaction status to :completed
  2. Create bookkeeping entry (debit CurrencyLedger.inbound, credit Fund.available)
  3. Increment assignment subject_count

  Money stays on the user's OPP merchant. Our bookkeeping is the source of truth
  for fund allocation. OPP withdrawals happen at payout time (UC-OPP-06).

  Status handling: `:pending` and `:failed` transactions are both completed by
  this function. The `:failed → :completed` upgrade resolves the race where the
  expiration worker marks a transaction failed before a late webhook arrives —
  the researcher's payment did succeed at OPP and we credit it. Only
  `:completed` transactions are refused (idempotency on duplicate webhooks).
  """
  def complete_transaction(provider_uid) when is_binary(provider_uid) do
    transaction =
      get_transaction_by_provider_uid!(provider_uid)
      |> Repo.preload(target_fund: [:available, :pending, currency_ledger: [:inbound, :outbound]])

    case transaction.status do
      :completed ->
        {:error, :already_completed}

      _ ->
        do_complete_transaction(transaction)
    end
  end

  defp do_complete_transaction(
         %Fund.TransactionModel{
           subject_count: subject_count,
           target_fund: %{
             available: %{identifier: fund_account_id},
             currency_ledger: %{inbound: %{identifier: inbound_account_id}}
           }
         } = transaction
       ) do
    reward_per_participant = get_reward_per_participant(transaction)
    total_amount = subject_count * reward_per_participant

    Multi.new()
    |> Multi.update(
      :transaction,
      Fund.TransactionModel.changeset(transaction, %{status: :completed})
    )
    |> Multi.run(:bookkeeping, fn _, _ ->
      Bookkeeping.Public.enter(%{
        idempotence_key: "complete:#{transaction.idempotence_key}",
        journal_message:
          "Pay-in #{total_amount} cents for #{subject_count} participants on fund ##{transaction.target_fund_id}",
        lines: [
          %{account: inbound_account_id, debit: total_amount},
          %{account: fund_account_id, credit: total_amount}
        ]
      })
    end)
    |> Multi.run(:update_subject_count, fn _, _ ->
      increment_subject_count(transaction.target_fund_id, subject_count)
    end)
    |> Repo.commit()
  end

  def fail_transaction(provider_uid) when is_binary(provider_uid) do
    transaction = get_transaction_by_provider_uid!(provider_uid)

    case transaction.status do
      :completed ->
        Logger.error(
          "[Budget] refusing late 'failed' for already-completed transaction #{provider_uid}; " <>
            "fund stays credited"
        )

        {:error, :already_completed}

      _ ->
        transaction
        |> Fund.TransactionModel.changeset(%{status: :failed})
        |> Repo.update()
    end
  end

  @pay_in_expiration_minutes 15

  @doc """
  Marks pending pay-in transactions older than `max_age_minutes` as `:failed`.

  Returns the number of transactions that were expired.
  """
  def expire_stale_pay_ins(max_age_minutes \\ @pay_in_expiration_minutes)
      when is_integer(max_age_minutes) and max_age_minutes > 0 do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    cutoff = NaiveDateTime.add(now, -max_age_minutes * 60, :second)

    {count, _} =
      from(t in Fund.TransactionModel,
        where: t.status == :pending and t.inserted_at < ^cutoff,
        update: [set: [status: :failed, updated_at: ^now]]
      )
      |> Repo.update_all([])

    if count > 0 do
      Logger.info("[Budget] Expired #{count} stale pending pay-in(s)")
    end

    count
  end

  def reconcile_transactions(opts, state), do: Fund.TransactionReconciliation.run(opts, state)

  @doc """
  Flags provider transactions that have no local pay-in row.
  See `Systems.Fund.TransactionOrphanReconciliation`.
  """
  def reconcile_orphaned_transactions(opts, state),
    do: Fund.TransactionOrphanReconciliation.run(opts, state)

  # --- Helpers ---

  defp get_reward_per_participant(%Fund.TransactionModel{target_fund_id: fund_id}) do
    from(a in Assignment.Model,
      join: i in assoc(a, :info),
      where: a.fund_id == ^fund_id,
      select: i.subject_reward
    )
    |> Repo.one() || 0
  end

  defp increment_subject_count(fund_id, additional_count) do
    from(i in Assignment.InfoModel,
      join: a in Assignment.Model,
      on: a.info_id == i.id,
      where: a.fund_id == ^fund_id,
      update: [inc: [subject_count: ^additional_count]]
    )
    |> Repo.update_all([])

    {:ok, :updated}
  end

  defp generate_invoice_id do
    env_id = Application.get_env(:core, :invoice_environment, "DEV")
    %{rows: [[number]]} = Repo.query!("SELECT nextval('invoice_number_seq')")
    padded = number |> Integer.to_string() |> String.pad_leading(4, "0")
    "NEXT-#{env_id}-#{padded}"
  end

  defp return_url(%Assignment.Model{id: assignment_id}) do
    base_url =
      Application.get_env(:core, :payment_webhook_base_url) ||
        Application.fetch_env!(:core, :base_url)

    "#{base_url}/assignment/#{assignment_id}/content"
  end

  defp get_currency(%{currency_ledger: %{currency: currency}}), do: currency
  defp get_currency(_), do: :EUR
end
