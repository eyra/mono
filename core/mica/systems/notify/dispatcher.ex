defmodule Systems.Notify.Dispatcher do
  @moduledoc """
  Event → Messages → Channel delivery.

  For an event, looks up the channels routed to it, asks each channel's
  adapter to build its payload, persists a `MessageModel` per channel, then
  hands each message to its channel for delivery. Delivery result flips the
  message status to `:sent` / `:failed`.

  Channels that decide the event isn't relevant to them can return `:skip`
  from `build_payload/1` — no message is persisted for that channel.
  """
  require Logger

  alias Core.Repo
  alias Ecto.Multi

  alias Systems.Notify
  alias Systems.Notify.EventModel
  alias Systems.Notify.MessageModel

  @doc """
  Fan an event out to all channels registered for its type. Persists a message
  per channel and delivers immediately (v1 has no batching / scheduling).
  Returns `{:ok, messages}` or `{:error, reason}`.
  """
  def dispatch(%EventModel{} = event) do
    channels = Notify.EventType.channels_for(event.type)

    with {:ok, messages} <- build_and_persist_messages(event, channels) do
      Enum.each(messages, &deliver/1)
      mark_dispatched(event)
      {:ok, messages}
    end
  end

  defp build_and_persist_messages(event, channels) do
    channels
    |> Enum.reduce(Multi.new(), fn channel, multi ->
      case build_payload(channel, event) do
        {:ok, payload} ->
          changeset =
            MessageModel.changeset(%MessageModel{}, %{
              event_id: event.id,
              channel: channel,
              payload: payload,
              status: :pending
            })

          Multi.insert(multi, {:message, channel}, changeset)

        :skip ->
          multi

        {:error, reason} ->
          Logger.warning(
            "[Notification] channel #{channel} build_payload failed for event #{event.id}: #{inspect(reason)}"
          )

          multi
      end
    end)
    |> Repo.commit()
    |> case do
      {:ok, changes} ->
        messages =
          changes
          |> Enum.filter(fn {k, _} -> match?({:message, _}, k) end)
          |> Enum.map(fn {_, msg} -> msg end)

        {:ok, messages}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  defp deliver(%MessageModel{} = message) do
    adapter = channel_adapter(message.channel)

    result =
      try do
        adapter.deliver(message)
      rescue
        error ->
          {:error, Exception.message(error)}
      end

    update_message_after_delivery(message, result)
  end

  defp update_message_after_delivery(message, :ok) do
    message
    |> MessageModel.changeset(%{
      status: :sent,
      delivered_at: DateTime.utc_now(),
      attempts: message.attempts + 1
    })
    |> Repo.update()
  end

  defp update_message_after_delivery(message, {:error, reason}) do
    message
    |> MessageModel.changeset(%{
      status: :failed,
      failure_reason: inspect(reason),
      attempts: message.attempts + 1
    })
    |> Repo.update()
  end

  defp mark_dispatched(event) do
    event
    |> EventModel.changeset(%{dispatched_at: DateTime.utc_now()})
    |> Repo.update()
  end

  defp build_payload(channel, event) do
    channel
    |> channel_adapter()
    |> apply(:build_payload, [event])
  end

  # Channel routing. Keeping this as a case rather than a data structure so a
  # rename shows up in `mix xref`.
  defp channel_adapter(:email), do: Notify.Channel.Email
  defp channel_adapter(:na), do: Notify.Channel.NA
end
