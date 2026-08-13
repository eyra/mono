defmodule Systems.Notify.Channel.Email do
  @moduledoc """
  Email channel adapter. Builds a Bamboo email per event and ships it via the
  existing `Systems.Email` pipeline.

  Payload shape: `%{"factory_fn" => atom_string, "args" => [...]}`. Rendering
  happens at delivery time in the recipient's locale — we persist only the raw
  args so a resend still respects locale/copy changes.

  Register per-event-type payload builders as `build_payload/1` clauses below.
  Unhandled types return `:skip` so the dispatcher just doesn't create an
  email message for them.
  """
  @behaviour Systems.Notify.Channel

  require Logger

  alias Core.Repo
  alias Systems.Account
  alias Systems.Email
  alias Systems.Notify.EventModel
  alias Systems.Notify.MessageModel

  @impl true
  def build_payload(%EventModel{type: "contribution_accepted"} = event) do
    {:ok,
     %{
       "factory_fn" => "contribution_accepted",
       "subject_user_id" => event.subject_user_id,
       "metadata" => event.metadata
     }}
  end

  def build_payload(%EventModel{type: "contribution_declined"} = event) do
    {:ok,
     %{
       "factory_fn" => "contribution_declined",
       "subject_user_id" => event.subject_user_id,
       "metadata" => event.metadata
     }}
  end

  def build_payload(_event), do: :skip

  @impl true
  def deliver(%MessageModel{payload: payload}) do
    with {:ok, user} <- fetch_user(payload["subject_user_id"]),
         {:ok, email} <- build_email(payload["factory_fn"], user, payload["metadata"]) do
      Email.Public.deliver_later(email)
      :ok
    end
  end

  defp fetch_user(nil), do: {:error, :no_recipient}

  defp fetch_user(user_id) do
    case Repo.get(Account.User, user_id) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end

  defp build_email("contribution_accepted", user, metadata) do
    {:ok, Email.Factory.contribution_accepted(user, metadata)}
  end

  defp build_email("contribution_declined", user, metadata) do
    {:ok, Email.Factory.contribution_declined(user, metadata)}
  end

  defp build_email(other, _user, _metadata),
    do: {:error, {:unknown_factory_fn, other}}

  # Email is out-of-band; the server has no way to unsend or mark-as-read a
  # message once it's been handed to the delivery worker. Nothing to do.
  @impl true
  def mark_seen(_message), do: :ok
end
