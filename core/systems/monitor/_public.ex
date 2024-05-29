defmodule Systems.Monitor.Public do
  alias Systems.Account.User
  alias Systems.Monitor.Queries
  alias Frameworks.Utility.Module

  require Logger

  def log(_, opts \\ [])

  def log(tuple, opts) when is_tuple(tuple) do
    tuple
    |> event()
    |> log(opts)
  end

  def log(event, opts) when is_list(event) do
    Logger.notice("MONITOR: #{inspect(event)}", ansi_color: :magenta)
    value = Keyword.get(opts, :value, 1)
    Queries.upsert_event(event, value)
  end

  def multi_log(_, _, opts \\ [])

  def multi_log(multi, tuple, opts) when is_tuple(tuple) do
    multi_log(multi, event(tuple), opts)
  end

  def multi_log(multi, event, opts) when is_list(event) do
    Logger.notice("MONITOR: #{inspect(event)}", ansi_color: :magenta)
    value = Keyword.get(opts, :value, 1)
    Queries.upsert_event(multi, event, value)
  end

  def event(%model{id: id}) do
    model = Module.to_model(model)
    ["#{model}=#{id}"]
  end

  def event({model, topic}) when is_atom(topic) do
    event(model) ++ ["topic=#{topic}"]
  end

  def event({model, topic, user_ref}) do
    user_id = User.user_id(user_ref)
    event({model, topic}) ++ ["user=#{user_id}"]
  end

  defdelegate clear(event), to: Queries

  defdelegate count(event_template), to: Queries
  defdelegate sum(event_template), to: Queries
  defdelegate unique(event_template), to: Queries
end
