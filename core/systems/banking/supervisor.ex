defmodule Systems.Banking.Supervisor do
  @moduledoc """
  Supervisor for Systems.Banking.BankAccountSupervisor instances.
  """
  use Supervisor

  @registry Systems.Banking.Registry
  @registry_key "bank_account"

  def start_link(args) do
    Registry.start_link(keys: :duplicate, name: @registry)
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init([_ | _] = config) do
    children =
      config
      |> Enum.map(&register(&1))
      |> Enum.map(&to_child(&1))

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp register({currency, account_number} = account) do
    Registry.register(@registry, @registry_key, {currency, account_number})
    account
  end

  defp to_child({currency, account_number}) do
    {Systems.Banking.AccountSupervisor, {currency, account_number}}
  end

  def bank_accounts() do
    Registry.lookup(@registry, @registry_key)
    |> Enum.map(fn {_currency, bank_account} -> bank_account end)
  end

  def currencies() do
    Registry.lookup(@registry, @registry_key)
    |> Enum.map(fn {currency, _bank_account} -> currency end)
  end
end
