defmodule Systems.Promotion.Private do
  @moduledoc false
  alias Core.Repo
  alias Ecto.Multi
  alias Frameworks.Signal
  alias Systems.Monitor
  alias Systems.Promotion

  def log_performance_event(%Promotion.Model{} = promotion, topic) do
    Multi.new()
    |> Monitor.Public.multi_log({promotion, topic})
    |> Signal.Public.multi_dispatch({:promotion, :performance_event},
      message: %{promotion: promotion}
    )
    |> Repo.commit()
  end
end
