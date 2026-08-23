defmodule Systems.Notify.EventModel do
  @moduledoc """
  A raw fact that something happened. Records the "what + who + when" —
  channels + timing are decided later by `Systems.Notify.Scheduler`.

  `metadata` holds event-type-specific raw data (IDs + snapshotted fields).
  Rendering to user-facing text happens at message-build time in the
  recipient's locale.
  """
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Account
  alias Systems.Notify

  schema "notify_event" do
    field(:type, :string)
    field(:metadata, :map, default: %{})
    field(:correlation_id, :string)
    field(:source, :string)
    field(:dispatched_at, :utc_datetime_usec)

    belongs_to(:subject_user, Account.User)
    belongs_to(:actor_user, Account.User)

    has_many(:messages, Notify.MessageModel, foreign_key: :event_id)

    timestamps()
  end

  @fields ~w(type metadata correlation_id source subject_user_id actor_user_id dispatched_at)a
  @required ~w(type subject_user_id)a

  def changeset(event, attrs) do
    event
    |> cast(attrs, @fields)
    |> validate_required(@required)
  end
end
