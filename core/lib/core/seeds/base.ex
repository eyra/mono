defmodule Core.Seeds.Base do
  @moduledoc """
  Seeds that must exist in every deploy environment (local, dev, test, staging, prod).

  All operations must be idempotent.
  """

  require Logger

  alias Systems.Budget
  alias Systems.Pool

  @doc """
  Runs all base seeds. Safe to run multiple times.
  """
  def seed do
    Logger.info("[Seeds.Base] Running base seeds")
    seed_panl_pool()
    seed_currency_ledgers()
    :ok
  end

  defp seed_panl_pool do
    Logger.info("[Seeds.Base] Ensuring Panl pool exists")
    Pool.Assembly.get_or_create_panl()
  end

  defp seed_currency_ledgers do
    Logger.info("[Seeds.Base] Ensuring EUR currency ledger exists")
    get_or_create_currency_ledger(:EUR)
  end

  defp get_or_create_currency_ledger(currency) do
    case Budget.CurrencyLedgerModel.get_by_currency(currency) do
      nil ->
        Logger.info("[Seeds.Base] Creating #{currency} currency ledger")
        Budget.CurrencyLedgerModel.create(currency) |> Core.Repo.insert!()

      _existing ->
        Logger.info("[Seeds.Base] #{currency} currency ledger already exists")
    end
  end
end
