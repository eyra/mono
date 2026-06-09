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

  alias Systems.Fund
  alias Systems.Bookkeeping
  alias Systems.Banking
  alias Systems.Payment

  defmodule FundError do
    @moduledoc false
    defexception [:message]
  end

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

  def list_pending_approvals(%Fund.Model{} = fund, preload \\ [:user]) do
    reward_query(fund, :pending_approval)
    |> preload(^preload)
    |> Repo.all()
  end

  # Default preload includes `:payment` so callers can read
  # `payment.inserted_at` as the settlement timestamp.
  def list_paid_rewards(%Fund.Model{} = fund, preload \\ [:user, :payment]) do
    reward_query(fund, :paid)
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

  def create_reward(%Fund.Model{} = fund, amount, user, idempotence_key)
      when is_integer(amount) and is_binary(idempotence_key) do
    Multi.new()
    |> create_reward(fund, amount, user, idempotence_key)
    |> Repo.commit()
  end

  def create_reward(
        multi,
        %Fund.Model{} = fund,
        amount,
        user,
        idempotence_key
      )
      when is_integer(amount) and is_binary(idempotence_key) do
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
    multi
    |> Multi.run(:fund_balance, fn _, _ ->
      if Fund.Model.amount_available(fund) >= amount do
        {:ok, true}
      else
        Logger.warning("Fund has not enough funds to make reward reservation")
        {:error, :no_funding}
      end
    end)
  end

  defp guard_fund_balance(multi, _, _), do: multi

  def payout_reward(idempotence_key) when is_binary(idempotence_key) do
    case get_reward(idempotence_key, Fund.RewardModel.preload_graph(:full)) do
      nil -> Logger.warning("No reward available to payout for #{idempotence_key}")
      reward -> make_payment(reward)
    end
  end

  @doc """
  Marks a reserved reward as awaiting researcher approval.

  Called when the participant completes the assignment task. The deposit was
  already made at apply time (see `create_reward/4`); this only flips the
  status so the researcher can act on it.

  Idempotent: calling on a reward that is already past `:reserved` is a no-op.
  """
  def mark_pending_approval(idempotence_key) when is_binary(idempotence_key) do
    case get_reward(idempotence_key, []) do
      nil ->
        Logger.warning("No reward to mark pending approval for #{idempotence_key}")
        {:error, :reward_not_found}

      %Fund.RewardModel{status: :reserved} = reward ->
        cas_to_pending_approval(reward, idempotence_key)

      %Fund.RewardModel{} = reward ->
        {:ok, reward}
    end
  end

  defp cas_to_pending_approval(%Fund.RewardModel{id: id}, idempotence_key) do
    query =
      from(r in Fund.RewardModel,
        where: r.id == ^id and r.status == ^:reserved,
        select: r
      )

    case Repo.update_all(query, set: [status: :pending_approval, updated_at: now()]) do
      {1, [reward]} ->
        {:ok, reward}

      {0, _} ->
        case get_reward(idempotence_key, []) do
          nil -> {:error, :reward_not_found}
          %Fund.RewardModel{} = reward -> {:ok, reward}
        end
    end
  end

  @doc """
  Approves a reward and pays it out to the participant's wallet.

  Atomic: the status flip and the payment Bookkeeping entry happen in one
  transaction. Idempotent on `:approved`/`:paid`.
  """
  def approve_reward(idempotence_key) when is_binary(idempotence_key) do
    case get_reward(idempotence_key, Fund.RewardModel.preload_graph(:full)) do
      nil ->
        Logger.warning("No reward to approve for #{idempotence_key}")
        {:error, :reward_not_found}

      %Fund.RewardModel{status: status} = reward when status in [:approved, :paid] ->
        {:ok, reward}

      %Fund.RewardModel{status: :rejected, fund: fund, amount: amount} = reward ->
        if Fund.Model.amount_available(fund) < amount do
          {:error, :insufficient_fund}
        else
          do_override_rejected(reward)
        end

      %Fund.RewardModel{status: status} = reward when status in [:reserved, :pending_approval] ->
        do_approve_reward(reward)
    end
  end

  defp do_approve_reward(%Fund.RewardModel{} = reward) do
    Multi.new()
    |> cas_status_step(:reward, reward, [:reserved, :pending_approval], status: :approved)
    |> approve_payment_step(reward)
    |> Repo.commit()
  end

  # Reject already rolled the deposit back to Fund.available, so payment comes
  # from there (the `deposit: nil` branch of create_payment_transaction).
  defp do_override_rejected(%Fund.RewardModel{} = reward) do
    Multi.new()
    |> cas_status_step(:reward, reward, [:rejected],
      status: :approved,
      rejection_reason: nil,
      rejected_at: nil
    )
    |> approve_payment_step(reward)
    |> Repo.commit()
  end

  # A reward must never be :approved with a nil payment_id.
  defp approve_payment_step(multi, %Fund.RewardModel{payment: %Bookkeeping.EntryModel{}} = reward) do
    Multi.run(multi, :payment, fn _, _ -> {:ok, reward} end)
  end

  defp approve_payment_step(multi, %Fund.RewardModel{} = reward) do
    Multi.run(multi, :payment, fn _, _ ->
      with {:ok, %{entry: payment}} <- create_payment_transaction(reward) do
        link_payment_transaction(reward, payment)
      end
    end)
  end

  # Compare-and-swap: the status precondition serializes concurrent transitions
  # so a losing writer hits 0 rows and rolls back instead of double-applying.
  defp cas_status_step(multi, name, %Fund.RewardModel{id: id}, from_statuses, set)
       when is_list(from_statuses) and is_list(set) do
    set = Keyword.put_new(set, :updated_at, now())

    Multi.run(multi, name, fn repo, _ ->
      query =
        from(r in Fund.RewardModel,
          where: r.id == ^id and r.status in ^from_statuses,
          select: r
        )

      case repo.update_all(query, set: set) do
        {1, [reward]} -> {:ok, reward}
        {0, _} -> {:error, :stale_reward}
      end
    end)
  end

  defp now, do: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

  @doc """
  Rejects a reward and returns the reserved money to the assignment fund.

  Atomic: the status flip and the deposit reversal happen in one transaction.
  Idempotent on `:rejected`.
  """
  def reject_reward(idempotence_key) when is_binary(idempotence_key) do
    reject_reward(idempotence_key, nil)
  end

  def reject_reward(idempotence_key, reason) when is_binary(idempotence_key) do
    case get_reward(idempotence_key, Fund.RewardModel.preload_graph(:full)) do
      nil ->
        Logger.warning("No reward to reject for #{idempotence_key}")
        {:error, :reward_not_found}

      %Fund.RewardModel{status: :rejected} = reward ->
        {:ok, reward}

      %Fund.RewardModel{status: status} when status in [:approved, :paid] ->
        {:error, :reward_already_approved}

      %Fund.RewardModel{status: status} = reward when status in [:reserved, :pending_approval] ->
        do_reject_reward(reward, reason)
    end
  end

  @doc """
  Multi-aware variant of `reject_reward/1`. Use when the rejection must commit
  atomically alongside other operations (e.g. flipping a `Crew.TaskModel` to
  `:rejected` in `Assignment.Public.reject_task/3`).

  On a `:rejected` reward this is a no-op; on `:approved`/`:paid` it fails the
  surrounding transaction with `{:error, :reward_already_approved}` (rather
  than raising deep in `rollback_deposit/2`). The status flip is a guarded
  compare-and-swap, so a concurrent transition makes this a safe rollback.

  The third argument is the optional rejection reason; nil leaves it unset.
  """
  def reject_reward(%Multi{} = multi, %Fund.RewardModel{} = reward) do
    reject_reward(multi, reward, nil)
  end

  def reject_reward(%Multi{} = multi, idempotence_key) when is_binary(idempotence_key) do
    reject_reward(multi, idempotence_key, nil)
  end

  def reject_reward(%Multi{} = multi, %Fund.RewardModel{status: :rejected}, _reason), do: multi

  def reject_reward(%Multi{} = multi, %Fund.RewardModel{status: status}, _reason)
      when status in [:approved, :paid] do
    Multi.run(multi, :reject_guard, fn _, _ -> {:error, :reward_already_approved} end)
  end

  def reject_reward(%Multi{} = multi, %Fund.RewardModel{} = reward, reason) do
    multi
    |> rollback_deposit(reward)
    |> cas_status_step(:reject_status, reward, [:reserved, :pending_approval],
      status: :rejected,
      rejection_reason: reason,
      rejected_at: now()
    )
  end

  def reject_reward(%Multi{} = multi, idempotence_key, reason) when is_binary(idempotence_key) do
    case get_reward(idempotence_key, Fund.RewardModel.preload_graph(:full)) do
      nil -> raise FundError, message: "No reward available to reject"
      reward -> reject_reward(multi, reward, reason)
    end
  end

  defp do_reject_reward(reward, reason) do
    Multi.new()
    |> reject_reward(reward, reason)
    |> Repo.commit()
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
  Rolls up a participant's reward situation into amounts (in cents), used by
  the home page rewards-summary card:

  - `pending_cents` — status `:reserved` or `:pending_approval` (waiting on
    researcher approval).
  - `approved_cents` — status `:approved`. The participant's currently
    available balance — eligible for payout.
  - `pending_payout_cents` — status `:pending_payout`. Funds locked while a
    payout request is in flight at the payment provider.
  - `paid_out_cents` — status `:paid`. Funds that have completed payout.
  - `rejected_cents` — status `:rejected`.

  All buckets are immutable per-status earned-amount snapshots (sum of
  `Fund.RewardModel.amount`) sharing a single source of truth (the reward
  rows), so they cannot drift relative to each other the way mixing reward
  sums with live wallet balances would.
  """
  def summarize_rewards(%Account.User{id: user_id}) do
    totals =
      from(r in Fund.RewardModel,
        where: r.user_id == ^user_id,
        group_by: r.status,
        select: {r.status, sum(r.amount)}
      )
      |> Repo.all()
      |> Enum.into(%{})

    amount = fn status -> Map.get(totals, status) || 0 end

    %{
      pending_cents: amount.(:reserved) + amount.(:pending_approval),
      approved_cents: amount.(:approved),
      pending_payout_cents: amount.(:pending_payout),
      paid_out_cents: amount.(:paid),
      rejected_cents: amount.(:rejected)
    }
  end

  @payout_threshold_cents 500

  @doc """
  Minimum approved balance (in cents) required to request a payout — €5.
  """
  def payout_threshold_cents, do: @payout_threshold_cents

  @doc """
  Requests a payout for all of the participant's `:approved` rewards.

  Vertical slice for UC-OPP-06 (MS.4 → MS.10, without MS.11 webhook handling):

    1. Validate the participant has an OPP merchant on file.
    2. Validate the available balance ≥ `@payout_threshold_cents`.
    3. Lock the eligible rewards: status `:approved` → `:pending_payout`.
    4. Call `Payment.Public.create_withdrawal/4` to initiate the OPP payout,
       keyed by the payout's idempotence key so retries never duplicate it.
    5. On failure *before* OPP accepts, revert the lock so the funds remain
       available. Once OPP accepts, the lock stands (reverting would risk a
       double payout); the status webhook drives it to `:completed`/`:failed`.

  Returns `{:ok, %{withdrawal: withdrawal, amount: cents}}` on success or
  one of:

    * `{:error, :no_merchant}` — participant has no OPP merchant_uid.
    * `{:error, {:below_threshold, cents}}` — available balance under €5.
    * `{:error, {:opp_failed, reason}}` — provider rejected the withdrawal;
      the lock has been reverted.

  Webhook handling (MS.11) and the eventual `:pending_payout` → `:paid`
  transition land in a follow-up PR.
  """
  def request_payout(%Account.User{} = user) do
    # Reload from the DB: prepare_payout/1 may have just provisioned the OPP
    # merchant and persisted merchant_uid, while the caller (e.g. a LiveView
    # socket assign) still holds a stale struct with merchant_uid: nil.
    case Repo.reload!(user) do
      %Account.User{merchant_uid: nil} ->
        {:error, :no_merchant}

      %Account.User{id: user_id, merchant_uid: merchant_uid} ->
        approved = list_approved_rewards(user_id)
        total = Enum.reduce(approved, 0, fn %{amount: amount}, acc -> acc + amount end)

        if total < @payout_threshold_cents do
          {:error, {:below_threshold, total}}
        else
          do_request_payout(user_id, merchant_uid, approved, total)
        end
    end
  end

  @doc """
  Pre-flight check for a payout request — pure / no side effects. Used by
  `prepare_payout/1` to gate the threshold + balance checks before any OPP
  call.
  """
  def payout_eligibility(%Account.User{id: user_id}) do
    total =
      list_approved_rewards(user_id)
      |> Enum.reduce(0, fn %{amount: amount}, acc -> acc + amount end)

    if total < @payout_threshold_cents do
      {:error, {:below_threshold, total}}
    else
      :ok
    end
  end

  @doc """
  Side-effecting pre-handoff check (UC-OPP-06.A1).

  Ensures the participant has an OPP merchant and a bank account, then
  reports payout readiness. Returns one of:

    * `:ok` — merchant is `status="live"` AND `compliance_status="verified"`
      AND has an `approved` bank account, and the approved balance is at or
      above the payout threshold.
    * `{:error, {:below_threshold, cents}}` — under €5; no OPP call made.
    * `{:error, {:kyc_required, url}}` — merchant/bank not yet payout-ready
      and `url` is a usable page to send the participant to (the merchant
      KYC overview when present, else the bank-account verification page).
    * `{:error, :kyc_unavailable}` — not payout-ready and OPP gave us no
      usable URL to route to; surface a generic "try again later" flash.
    * `{:error, reason}` — an OPP call failed.

  Per the ticket, no local KYC tracking in MVP — we re-check OPP each
  time the participant clicks Uitbetalen.
  """
  def prepare_payout(%Account.User{} = user) do
    with :ok <- payout_eligibility(user),
         {:ok, {_user, merchant}} <- Payment.Public.ensure_merchant_for(user),
         {:ok, bank_account} <- Payment.Public.ensure_bank_account_for(merchant.uid) do
      payout_ready_for(merchant, bank_account)
    end
  end

  # Fully payout-ready: live + verified merchant with an approved bank
  # account. (compliance_status "verified" is documented to subsume bank
  # approval, but we check the bank status explicitly so a live withdrawal
  # is never fired against an unapproved account.)
  defp payout_ready_for(
         %{status: "live", compliance_status: "verified"},
         %{status: "approved"}
       ),
       do: :ok

  # Merchant itself is done — only the bank step remains. Send straight to
  # the bank-account verification page rather than the (now redundant)
  # merchant overview.
  defp payout_ready_for(
         %{status: "live", compliance_status: "verified"},
         %{verification_url: verification_url}
       )
       when is_binary(verification_url) and verification_url != "",
       do: {:error, {:kyc_required, verification_url}}

  # Merchant not yet done — route to the merchant KYC overview (the
  # comprehensive checklist) when OPP gave us one.
  defp payout_ready_for(%{overview_url: overview_url}, _bank_account)
       when is_binary(overview_url) and overview_url != "",
       do: {:error, {:kyc_required, overview_url}}

  # No overview page (common once only the bank step remains) — fall back to
  # the bank-account verification page.
  defp payout_ready_for(_merchant, %{verification_url: verification_url})
       when is_binary(verification_url) and verification_url != "",
       do: {:error, {:kyc_required, verification_url}}

  # Not ready and no usable URL to send the participant to.
  defp payout_ready_for(_merchant, _bank_account), do: {:error, :kyc_unavailable}

  # Re-verify readiness at withdrawal time against fresh OPP state. Guards
  # against the merchant/bank status drifting between the handoff screen and
  # the confirm click (TOCTOU). Returns the same shape as payout_ready_for/2.
  defp recheck_payout_ready(merchant_uid) do
    with {:ok, merchant} <- Payment.Public.get_merchant(merchant_uid),
         {:ok, bank_account} <- Payment.Public.ensure_bank_account_for(merchant_uid) do
      payout_ready_for(merchant, bank_account)
    end
  end

  defp do_request_payout(user_id, merchant_uid, approved, total) do
    case recheck_payout_ready(merchant_uid) do
      :ok -> lock_and_withdraw(user_id, merchant_uid, approved, total)
      {:error, _} = error -> error
    end
  end

  defp lock_and_withdraw(user_id, merchant_uid, approved, total) do
    # Resolve before locking: a missing platform merchant must fail cleanly, not crash mid-payout.
    case Payment.Public.platform_merchant_uid() do
      nil ->
        {:error, :no_platform_merchant}

      platform_uid ->
        reward_ids = Enum.map(approved, fn %{id: id} -> id end)

        case lock_for_payout(user_id, reward_ids, total) do
          {:ok, payout} ->
            withdraw_for_payout(payout, platform_uid, merchant_uid, total, reward_ids)

          {:error, _reason} ->
            {:error, :lock_failed}
        end
    end
  end

  # Per-leg idempotence keys so retries never double-move money.
  defp withdraw_for_payout(payout, platform_uid, merchant_uid, total, reward_ids) do
    base_key = Fund.PayoutModel.idempotence_key(payout)

    case Payment.Public.create_charge(
           platform_uid,
           merchant_uid,
           total,
           base_key <> ",type=charge"
         ) do
      {:ok, _charge} ->
        # OPP accepted the charge — never revert past here (double-payout risk).
        withdraw_after_charge(payout, merchant_uid, total, base_key)

      {:error, reason} ->
        # Nothing moved yet — safe to revert (UC-OPP-06.A3).
        revert_payout_lock(reward_ids, "opp_charge_failed: #{inspect(reason)}")
        {:error, {:opp_failed, reason}}
    end
  end

  defp withdraw_after_charge(payout, merchant_uid, total, base_key) do
    attrs = %{amount: total, description: "Reward payout"}

    case Payment.Public.create_withdrawal(
           merchant_uid,
           :EUR,
           attrs,
           base_key <> ",type=withdrawal"
         ) do
      {:ok, withdrawal} ->
        record_withdrawal(payout, withdrawal, total)

      {:error, reason} ->
        # Funds already on the participant merchant — don't revert; SF-OPP-02 completes it.
        Logger.error(
          "[Fund] charge succeeded but withdrawal failed for payout #{payout.id}; " <>
            "left :pending for reconciliation: #{inspect(reason)}"
        )

        {:error, {:opp_failed, reason}}
    end
  end

  defp record_withdrawal(payout, %{uid: uid} = withdrawal, total) do
    case payout |> Fund.PayoutModel.changeset(%{provider_uid: uid}) |> Repo.update() do
      {:ok, payout} ->
        {:ok, %{payout: payout, withdrawal: withdrawal, amount: total}}

      {:error, _changeset} ->
        # Withdrawal exists at OPP but uid unsaved — don't revert; SF-OPP-02 recovers it.
        Logger.error(
          "[Fund] OPP withdrawal #{uid} created but provider_uid not persisted for " <>
            "payout #{payout.id}; left :pending for reconciliation"
        )

        {:ok, %{payout: payout, withdrawal: withdrawal, amount: total}}
    end
  end

  defp lock_for_payout(user_id, reward_ids, total) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    Multi.new()
    |> Multi.insert(
      :payout,
      Fund.PayoutModel.changeset(%Fund.PayoutModel{}, %{
        user_id: user_id,
        amount_cents: total,
        status: :pending
      })
    )
    |> Multi.run(:lock_rewards, fn _repo, %{payout: %{id: payout_id}} ->
      {count, _} =
        from(r in Fund.RewardModel, where: r.id in ^reward_ids)
        |> Repo.update_all(set: [status: :pending_payout, payout_id: payout_id, updated_at: now])

      {:ok, count}
    end)
    |> Repo.commit()
    |> case do
      {:ok, %{payout: payout}} -> {:ok, payout}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  defp revert_payout_lock(reward_ids, failure_reason) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    Multi.new()
    |> Multi.run(:payout, fn _repo, _changes ->
      # Look up the (just-created) :pending payout via any reward's
      # payout_id. They all share the same payout because lock_for_payout
      # assigns one payout_id to the whole batch.
      case Repo.one(
             from(r in Fund.RewardModel,
               where: r.id in ^reward_ids and not is_nil(r.payout_id),
               select: r.payout_id,
               limit: 1
             )
           ) do
        nil ->
          {:ok, nil}

        payout_id ->
          payout = Repo.get!(Fund.PayoutModel, payout_id)

          payout
          |> Fund.PayoutModel.changeset(%{
            status: :failed,
            failure_reason: failure_reason
          })
          |> Repo.update()
      end
    end)
    |> Multi.update_all(
      :rewards,
      from(r in Fund.RewardModel, where: r.id in ^reward_ids),
      set: [status: :approved, payout_id: nil, updated_at: now]
    )
    |> Repo.commit()

    :ok
  end

  defp list_approved_rewards(user_id) do
    from(r in Fund.RewardModel,
      where: r.user_id == ^user_id and r.status == :approved
    )
    |> Repo.all()
  end

  @doc """
  Applies an OPP withdrawal status change to the linked `Fund.PayoutModel`
  and its rewards.

  OPP statuses collapse into local vocab:

      "completed"   -> Payout :completed; rewards :pending_payout -> :paid
      "failed"      -> Payout :failed;    rewards :pending_payout -> :approved
      "disapproved" -> Payout :failed;    rewards :pending_payout -> :approved
      (other)       -> no-op (logged)

  Idempotent: once a Payout is in a terminal state, subsequent calls
  short-circuit. If the OPP withdrawal UID isn't linked to any Payout
  (e.g. a webhook for a deposit-side transaction was misrouted, or the
  webhook arrived before the request_payout DB write committed), the
  call logs and returns `:ok`.

  Returns `{:ok, payout}` for terminal transitions, `:ok` when no
  Payout was found, and `{:error, reason}` for DB failures.
  """
  def apply_withdrawal_status(provider_uid, opp_status)
      when is_binary(provider_uid) and is_binary(opp_status) do
    case Repo.get_by(Fund.PayoutModel, provider_uid: provider_uid) do
      nil ->
        Logger.warning("[Fund] withdrawal #{provider_uid} not linked to any Payout — ignoring")

        :ok

      %Fund.PayoutModel{status: status} = payout when status in [:completed, :failed] ->
        # Already terminal. OPP retries webhooks; tolerate the duplicate.
        {:ok, payout}

      %Fund.PayoutModel{} = payout ->
        apply_status(payout, opp_status)
    end
  end

  defp apply_status(%Fund.PayoutModel{} = payout, "completed") do
    finalize_payout(payout, :completed, :paid, nil)
  end

  defp apply_status(%Fund.PayoutModel{} = payout, opp_status)
       when opp_status in ["failed", "disapproved"] do
    # Don't revert rewards to :approved: the charge already moved funds, so a
    # re-payout would charge again. SF-OPP-02 reconciles.
    fail_payout(payout, "opp_status: #{opp_status}")
  end

  defp apply_status(%Fund.PayoutModel{provider_uid: uid}, opp_status) do
    Logger.info("[Fund] withdrawal #{uid} OPP status=#{opp_status} — no local transition")

    :ok
  end

  defp finalize_payout(
         %Fund.PayoutModel{id: payout_id} = payout,
         payout_status,
         reward_status,
         failure_reason
       ) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    result =
      Multi.new()
      |> Multi.update(
        :payout,
        Fund.PayoutModel.changeset(payout, %{
          status: payout_status,
          failure_reason: failure_reason
        })
      )
      |> Multi.update_all(
        :rewards,
        from(r in Fund.RewardModel,
          where: r.payout_id == ^payout_id and r.status == :pending_payout
        ),
        set: [status: reward_status, updated_at: now]
      )
      |> Repo.commit()

    case result do
      {:ok, %{payout: payout}} ->
        Signal.Public.dispatch({:fund_rewards_summary, :updated}, %{user_id: payout.user_id})
        {:ok, payout}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  defp fail_payout(%Fund.PayoutModel{} = payout, failure_reason) do
    case payout
         |> Fund.PayoutModel.changeset(%{status: :failed, failure_reason: failure_reason})
         |> Repo.update() do
      {:ok, payout} ->
        Signal.Public.dispatch({:fund_rewards_summary, :updated}, %{user_id: payout.user_id})
        {:ok, payout}

      {:error, _changeset} = error ->
        error
    end
  end

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
end
