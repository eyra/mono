defmodule BankingProxy.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, [])
  end

  @impl true
  def init(:ok) do
    children = [
      {Bunq, Application.fetch_env!(:banking_proxy, :backend_params)}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
