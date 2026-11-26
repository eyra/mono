defmodule Systems.Notify.Public do
  @moduledoc """
  Public API for `Systems.Notify`. Domain code calls `record_event/1` from
  wherever a notifiable thing happens; the scheduler + channels take it from
  there.
  """
  use MicaWeb, :verified_routes

  require Logger

  import Ecto.Query

  alias Mica.Repo

  alias Systems.Monitor
  alias Systems.Notify
  alias Systems.Notify.EventModel
  alias Systems.Notify.EventType
  alias Systems.Notify.MessageModel
  alias Systems.Notify.EventAttrs
  alias Systems.Notify.Scheduler

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

  Idempotent: messages already `:seen` are ignored. A message whose channel the
  composition doesn't have is marked `:failed` instead and not counted.
  """
  def mark_seen(%{id: user_id}, opts) when is_list(opts) do
    seen =
      user_id
      |> messages_to_mark_seen(opts)
      |> Enum.map(&mark_message_seen/1)
      |> Enum.count(&(&1 == :seen))

    {:ok, seen}
  end

  defp messages_to_mark_seen(user_id, opts) do
    correlation_id = Keyword.get(opts, :correlation_id)
    event_types = Keyword.get(opts, :event_types, []) |> Enum.map(&to_string/1)

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
    case Notify.Channel.adapter(channel) do
      {:ok, adapter} ->
        run_mark_seen(adapter, message)

        message
        |> MessageModel.changeset(%{status: :seen, seen_at: DateTime.utc_now()})
        |> Repo.update()

        :seen

      {:error, reason} ->
        Logger.warning("[Notify] message #{message.id} has unknown channel #{inspect(channel)}")

        message
        |> MessageModel.changeset(%{status: :failed, failure_reason: inspect(reason)})
        |> Repo.update()

        :failed
    end
  end

  defp run_mark_seen(adapter, %MessageModel{channel: channel} = message) do
    if function_exported?(adapter, :mark_seen, 1) do
      case safe_mark_seen(adapter, message) do
        :ok ->
          :ok

        other ->
          Logger.warning(
            "[Notify] channel #{channel} mark_seen returned #{inspect(other)} for message #{message.id}"
          )
      end
    end
  end

  defp safe_mark_seen(adapter, message) do
    adapter.mark_seen(message)
  rescue
    error ->
      {:error, Exception.message(error)}
  end

  @doc """
  The button of a next action that a notification on the `:na` (Actions)
  channel shows: it opens the notification (`open_message/2`), which marks it
  seen and then leads to `to`. Without a notification in `params` (the next
  action wasn't delivered through Notify), it leads to `to` directly.

  Opening changes state, so it is a POST with the page's CSRF token
  (`POST /notify/open/:id`): another site can't open a user's notifications.
  The action also says where it leads (`destination`), for a client that
  can't send that POST, such as the app's Home (`Home.BFFPage`).
  """
  def open_action(%{"notify_message_id" => message_id}, to),
    do: %{type: :http_post, to: ~m"/notify/open/#{message_id}", destination: to}

  def open_action(_params, to), do: %{type: :redirect, to: to}

  @doc """
  Opens `user`'s notification message `message_id` on the `:na` channel: marks
  it seen, which clears its next action (`mark_seen/2`), and returns
  `{:ok, to}` with where the next action's button leads. `:error` when `user`
  has no such message.
  """
  def open_message(user, message_id) do
    with %MessageModel{payload: payload} = message <- get_message(user, message_id),
         {:ok, to} <- Notify.Channel.NA.target(payload) do
      if message.status != :seen, do: mark_message_seen(message)
      {:ok, to}
    else
      _ -> :error
    end
  end

  @doc """
  Where the button of `user`'s notification message `message_id` on the `:na`
  channel leads, without marking it seen: `{:ok, to}`, or `:error` when `user`
  has no such message. For a GET of `/notify/open/:id`, such as the button
  opened in a new tab: only a click (the POST) marks it seen.
  """
  def message_target(user, message_id) do
    case get_message(user, message_id) do
      %MessageModel{payload: payload} -> Notify.Channel.NA.target(payload)
      nil -> :error
    end
  end

  defp get_message(%{id: user_id}, message_id) do
    from(m in MessageModel,
      join: e in EventModel,
      on: e.id == m.event_id,
      where: m.id == ^message_id and m.channel == ^:na and e.subject_user_id == ^user_id
    )
    |> Repo.one()
  end

  @doc """
  The events of `type` with `correlation_id` recorded so far, of all users or
  of the user with `subject_user_id`: `%{subject_user_id: id, metadata: map}`
  each, also those already seen.
  """
  def list_recorded(type, correlation_id, subject_user_id \\ nil) do
    from(e in EventModel,
      where: e.type == ^to_string(type) and e.correlation_id == ^correlation_id,
      select: %{subject_user_id: e.subject_user_id, metadata: e.metadata}
    )
    |> where_subject(subject_user_id)
    |> Repo.all()
  end

  defp where_subject(query, nil), do: query
  defp where_subject(query, user_id), do: from(e in query, where: e.subject_user_id == ^user_id)

  # Fire-and-forget metric log. A failure here shouldn't roll back the event.
  defp log_to_monitor(%EventModel{type: type, subject_user_id: user_id}) do
    try do
      Monitor.Public.log(["notify=#{type}", "user=#{user_id}"])
    rescue
      error ->
        Logger.warning("[Notify] monitor log failed: #{Exception.message(error)}")
    end
  end
end
