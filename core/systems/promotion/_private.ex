defmodule Systems.Promotion.Private do
  alias Ecto.Multi
  alias Core.Repo
  alias Frameworks.Signal

  alias Systems.Promotion
  alias Systems.Monitor

  def log_performance_event(%Promotion.Model{} = promotion, topic) do
    Multi.new()
    |> Monitor.Public.multi_log({promotion, topic})
    |> Signal.Public.multi_dispatch({:promotion, :performance_event}, %{promotion: promotion})
    |> Repo.transaction()
  end
end
