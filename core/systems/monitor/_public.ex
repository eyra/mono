defmodule Systems.Monitor.Public do
  alias Systems.Monitor.Queries

  require Logger

  def log(event, opts \\ []) when is_list(event) do
    Logger.notice("MONITOR: #{inspect(event)}", ansi_color: :magenta)
    value = Keyword.get(opts, :value, 1)
    Queries.upsert_event(event, value)
  end

  defdelegate clear(event), to: Queries

  defdelegate count(event_template), to: Queries
  defdelegate sum(event_template), to: Queries
  defdelegate unique(event_template), to: Queries
end
