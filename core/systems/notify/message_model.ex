defmodule Systems.Notify.MessageModel do
  @moduledoc """
  A message produced from an event for one specific channel. Channel adapters
  interpret `payload` shape (e.g. email carries `%{subject, text, html}`, NA
  carries `%{action_module, key, params}`).
  """
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Notify

  @channels ~w(email na)a
  @statuses ~w(pending sent failed skipped seen)a

  schema "notify_message" do
    field(:channel, Ecto.Enum, values: @channels)
    field(:payload, :map, default: %{})
    field(:status, Ecto.Enum, values: @statuses, default: :pending)
    field(:delivered_at, :utc_datetime_usec)
    field(:seen_at, :utc_datetime_usec)
    field(:failure_reason, :string)
    field(:attempts, :integer, default: 0)

    belongs_to(:event, Notify.EventModel)

    timestamps()
  end

  @fields ~w(channel payload status delivered_at seen_at failure_reason attempts event_id)a
  @required ~w(channel event_id)a

  def channels, do: @channels
  def statuses, do: @statuses

  def changeset(message, attrs) do
    message
    |> cast(attrs, @fields)
    |> validate_required(@required)
  end
end
