defmodule Systems.Notify.Public do
  @moduledoc """
  Public API for `Systems.Notify`. Domain code calls `record_event/1` from
  wherever a notifiable thing happens; the scheduler + channels take it from
  there.
  """
  import Ecto.Query

  alias Core.Repo
  alias Systems.Monitor
  alias Systems.Notify
  alias Systems.Notify.EventAttrs
  alias Systems.Notify.EventModel
  alias Systems.Notify.EventType
  alias Systems.Notify.MessageModel
  alias Systems.Notify.Scheduler

  require Logger

  @doc """
  Record a domain event and hand it to the scheduler.

  Also increments a `Systems.Monitor` counter for aggregate observability;
  Monitor failures don't fail the event persistence.
  """
  def record_event(%EventAttrs{} = attrs) do
    normalized = normalize(attrs)

    with :ok <- validate_type(normalized.type),
         {:ok, event} <- insert_event(normalized) do
      log_to_monitor(event)
      Scheduler.schedule(event)
      {:ok, event}
    end
  end

  defp normalize(%EventAttrs{} = attrs) do
    %{
      type: to_string(attrs.type),
      subject_user_id: user_id(attrs.subject_user),
      actor_user_id: user_id(attrs.actor_user),
      metadata: attrs.metadata,
      correlation_id: attrs.correlation_id,
      source: source(attrs.source)
    }
  end

  # Accept a module atom (`Systems.Assignment.Switch`) or a plain string; store
  # as string so the DB column stays portable + inspectable.
  defp source(nil), do: nil
  defp source(module) when is_atom(module), do: inspect(module)
  defp source(str) when is_binary(str), do: str

  defp user_id(nil), do: nil
  defp user_id(%{id: id}), do: id

  defp validate_type(type) do
    if EventType.known?(type) do
      :ok
    else
      {:error, {:unknown_event_type, type}}
    end
  end

  defp insert_event(attrs) do
    %EventModel{}
    |> EventModel.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Mark messages as seen by the user. Each channel adapter's `mark_seen/1`
  callback (if implemented) runs the side effect (e.g. NA clears the NBA);
  message status flips to `:seen` and `seen_at` stamped.

  Filter options (at least one required):

      * `correlation_id: "participation:42"` — match a specific correlation
      * `event_types: [:contribution_accepted, :contribution_declined]` — match by type

  Idempotent: messages already `:seen` are ignored.
  """
  def mark_seen(%{id: user_id}, opts) when is_list(opts) do
    messages = messages_to_mark_seen(user_id, opts)

    Enum.each(messages, &mark_message_seen/1)

    {:ok, length(messages)}
  end

  defp messages_to_mark_seen(user_id, opts) do
    correlation_id = Keyword.get(opts, :correlation_id)
    event_types = opts |> Keyword.get(:event_types, []) |> Enum.map(&to_string/1)

    query =
      from(m in MessageModel,
        join: e in EventModel,
        on: e.id == m.event_id,
        where: e.subject_user_id == ^user_id and m.status != :seen
      )

    query
    |> maybe_filter_correlation(correlation_id)
    |> maybe_filter_event_types(event_types)
    |> Repo.all()
  end

  defp maybe_filter_correlation(query, nil), do: query

  defp maybe_filter_correlation(query, correlation_id) do
    from([m, e] in query, where: e.correlation_id == ^correlation_id)
  end

  defp maybe_filter_event_types(query, []), do: query

  defp maybe_filter_event_types(query, event_types) do
    from([m, e] in query, where: e.type in ^event_types)
  end

  defp mark_message_seen(%MessageModel{channel: channel} = message) do
    adapter = channel_adapter(channel)

    if function_exported?(adapter, :mark_seen, 1) do
      case safe_mark_seen(adapter, message) do
        :ok ->
          :ok

        other ->
          Logger.warning("[Notify] channel #{channel} mark_seen returned #{inspect(other)} for message #{message.id}")
      end
    end

    message
    |> MessageModel.changeset(%{status: :seen, seen_at: DateTime.utc_now()})
    |> Repo.update()
  end

  defp safe_mark_seen(adapter, message) do
    adapter.mark_seen(message)
  rescue
    error ->
      {:error, Exception.message(error)}
  end

  # Keep in sync with Dispatcher.channel_adapter/1
  defp channel_adapter(:email), do: Notify.Channel.Email
  defp channel_adapter(:na), do: Notify.Channel.NA

  # Fire-and-forget metric log. A failure here shouldn't roll back the event.
  defp log_to_monitor(%EventModel{type: type, subject_user_id: user_id}) do
    Monitor.Public.log(["notify=#{type}", "user=#{user_id}"])
  rescue
    error ->
      Logger.warning("[Notify] monitor log failed: #{Exception.message(error)}")
  end
end
