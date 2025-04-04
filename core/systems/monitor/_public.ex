defmodule Systems.Monitor.Public do
  use Core, :public
  alias Ecto.Multi
  alias Core.Repo
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
    Logger.info("MONITOR: #{inspect(event)}", ansi_color: :magenta)
    value = Keyword.get(opts, :value, 1)
    Queries.upsert_event(event, value)
  end

  def multi_log(_, _, opts \\ [])

  def multi_log(multi, tuple, opts) when is_tuple(tuple) do
    multi_log(multi, event(tuple), opts)
  end

  def multi_log(multi, event, opts) when is_list(event) do
    Logger.info("MONITOR: #{inspect(event)}", ansi_color: :magenta)
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

  def reset(event_template) when is_tuple(event_template) do
    event_template
    |> event()
    |> reset()
  end

  def reset(event_template) when is_list(event_template) do
    Multi.new()
    |> multi_reset(event_template)
    |> Repo.transaction()
  end

  def multi_reset(%Multi{} = multi, event_template) when is_tuple(event_template) do
    multi_reset(multi, event_template |> event())
  end

  def multi_reset(%Multi{} = multi, event_template) when is_list(event_template) do
    uuid = Ecto.UUID.generate()

    sum_name = "sum_#{uuid}"
    event_name = "event_#{uuid}"

    multi
    |> Multi.run(sum_name, fn _, _ ->
      {:ok, sum(event_template)}
    end)
    |> Multi.run(event_name, fn _, %{^sum_name => sum} ->
      log(event_template ++ ["action=reset"], value: -sum)
    end)
  end

  defdelegate clear(event), to: Queries

  defdelegate count(event_template), to: Queries
  defdelegate sum(event_template), to: Queries
  defdelegate unique(event_template), to: Queries

  def exists?(event) do
    count(event) > 0
  end
end
