defmodule Systems.Banking.AccountSupervisor do
  @moduledoc """
  A bank account under supervision of Systems.Banking.AccountSupervisor
  """
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init({currency, account_number}) do
    children = [
      {Systems.Banking.Public.backend(), account_number},
      {Systems.Banking.Fetcher, currency: currency, strategy: Systems.Budget.AccountStrategy}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
