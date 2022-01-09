defmodule BankingProxy.App do
  use Application

  def start(_type, _args) do
    BankingProxy.Supervisor.start_link()
  end
end
