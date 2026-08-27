defmodule Systems.Notify.Channel.NA do
  @moduledoc """
  Next-Action channel adapter. Creates an NBA on the recipient's Home for the
  event, via the existing `Systems.NextAction` infrastructure.

  Payload shape: `%{"action_module" => module_string, "key" => string,
  "params" => map}`. Rendering of the NBA card copy still happens in
  `<action_module>.to_view_model/2` at request time — that keeps locale-live
  and lets the NBA update if the underlying data changes.
  """
  @behaviour Systems.Notify.Channel

  alias Core.Repo
  alias Systems.Account
  alias Systems.NextAction
  alias Systems.Notify.EventModel
  alias Systems.Notify.MessageModel

  require Logger

  @impl true
  def build_payload(%EventModel{
        type: "contribution_accepted",
        metadata: %{"assignment_id" => assignment_id} = metadata
      }) do
    {:ok,
     %{
       "action_module" => "Elixir.Systems.Assignment.NextActions.ContributionReviewed",
       "key" => "#{assignment_id}:accepted",
       "params" => %{
         "assignment_id" => assignment_id,
         "node_id" => Map.get(metadata, "node_id"),
         "outcome" => "accepted"
       }
     }}
  end

  def build_payload(%EventModel{
        type: "contribution_declined",
        metadata: %{"assignment_id" => assignment_id} = metadata
      }) do
    {:ok,
     %{
       "action_module" => "Elixir.Systems.Assignment.NextActions.ContributionReviewed",
       "key" => "#{assignment_id}:declined",
       "params" => %{
         "assignment_id" => assignment_id,
         "node_id" => Map.get(metadata, "node_id"),
         "outcome" => "declined"
       }
     }}
  end

  def build_payload(_event), do: :skip

  @impl true
  def deliver(%MessageModel{event_id: event_id, payload: payload}) do
    with {:ok, event} <- fetch_event(event_id),
         {:ok, user} <- fetch_user(event.subject_user_id),
         {:ok, action_module} <- resolve_module(payload["action_module"]) do
      NextAction.Public.create_next_action(user, action_module,
        key: payload["key"],
        params: payload["params"]
      )

      :ok
    end
  end

  defp fetch_event(event_id) do
    case Repo.get(EventModel, event_id) do
      nil -> {:error, :event_not_found}
      event -> {:ok, event}
    end
  end

  defp fetch_user(nil), do: {:error, :no_recipient}

  defp fetch_user(user_id) do
    case Repo.get(Account.User, user_id) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end

  defp resolve_module(module_string) when is_binary(module_string) do
    module = String.to_existing_atom(module_string)
    {:ok, module}
  rescue
    ArgumentError -> {:error, {:unknown_action_module, module_string}}
  end

  @impl true
  def mark_seen(%MessageModel{event_id: event_id, payload: payload}) do
    with {:ok, event} <- fetch_event(event_id),
         {:ok, user} <- fetch_user(event.subject_user_id),
         {:ok, action_module} <- resolve_module(payload["action_module"]) do
      NextAction.Public.clear_next_action(user, action_module, key: payload["key"])
      :ok
    end
  end
end
