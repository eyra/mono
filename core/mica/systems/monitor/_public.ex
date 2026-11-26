defmodule Systems.Monitor.Public do
  use Mica, :public
  alias Ecto.Multi
  alias Mica.Repo
  alias Systems.Account.User
  alias Systems.Monitor.Queries
  alias Frameworks.Utility.Module

  require Logger

  # Identifier keys whose value points at one person: a user, or a model with one
  # row per user. They stay out of the telemetry metadata, so a metric doesn't get
  # a series per participant.
  @person_keys ["user", "account_features"]

  def log(_, opts \\ [])

  def log(tuple, opts) when is_tuple(tuple) do
    tuple
    |> event()
    |> log(opts)
  end

  def log(event, opts) when is_list(event) do
    Multi.new()
    |> multi_log(event, opts)
    |> Repo.commit()
  end

  def multi_log(_, _, opts \\ [])

  def multi_log(multi, tuple, opts) when is_tuple(tuple) do
    multi_log(multi, event(tuple), opts)
  end

  @doc """
  Adds the event to the Multi. Once it commits, the event is also emitted as the
  telemetry event `[:monitor, :event, :count]` with the value as `count` and the
  identifier's keys as metadata, without the keys that point at one person, such as
  `user` and `account_features` (see `Mica.AppSignal.TelemetryHandler`).
  """
  def multi_log(multi, event, opts) when is_list(event) do
    Logger.info("MONITOR: #{inspect(event)}", ansi_color: :magenta)
    value = Keyword.get(opts, :value, 1)

    multi
    |> Queries.upsert_event(event, value)
    |> Multi.run("telemetry_#{Ecto.UUID.generate()}", fn _, _ ->
      {:ok, Repo.after_commit(fn -> execute_telemetry(event, value) end)}
    end)
  end

  defp execute_telemetry(event, value) do
    :telemetry.execute([:monitor, :event, :count], %{count: value}, telemetry_metadata(event))
  end

  defp telemetry_metadata(event) do
    for entry <- event,
        [key, value] <- [String.split(entry, "=", parts: 2)],
        key not in @person_keys,
        into: %{},
        do: {key, value}
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
    |> Repo.commit()
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
      reset_event = event_template ++ ["action=reset"]
      Logger.info("MONITOR: #{inspect(reset_event)}", ansi_color: :magenta)
      Queries.upsert_event(reset_event, -sum)
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
