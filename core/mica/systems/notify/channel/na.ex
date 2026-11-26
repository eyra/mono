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

  require Logger

  alias Mica.Repo
  alias Systems.Account
  alias Systems.NextAction
  alias Systems.Notify.EventModel
  alias Systems.Notify.EventType
  alias Systems.Notify.MessageModel

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

  # An event whose declaration names its next action
  # (`Systems.Notify.EventDeclaration`): keyed by its correlation, with its
  # metadata as params.
  def build_payload(%EventModel{type: type, correlation_id: key, metadata: metadata}) do
    options = EventType.options_for(type)

    case Keyword.fetch(options, :next_action) do
      {:ok, action_module} ->
        {:ok,
         %{
           "action_module" => to_string(action_module),
           "key" => key,
           "params" => metadata,
           "priority" => options |> Keyword.get(:priority, :normal) |> to_string()
         }}

      :error ->
        :skip
    end
  end

  # The next action's params carry the message (`notify_message_id`), so its
  # button can open it through `Notify.Public.open_action/2`.
  @impl true
  def deliver(%MessageModel{id: message_id, event_id: event_id, payload: payload}) do
    with {:ok, event} <- fetch_event(event_id),
         {:ok, user} <- fetch_user(event.subject_user_id),
         {:ok, action_module} <- resolve_module(payload["action_module"]) do
      NextAction.Public.create_next_action(
        user,
        action_module,
        [
          key: payload["key"],
          params: Map.put(payload["params"] || %{}, "notify_message_id", message_id)
        ] ++ priority(payload)
      )

      :ok
    end
  end

  defp priority(%{"priority" => priority}) when priority in ["low", "normal", "high"],
    do: [priority: String.to_existing_atom(priority)]

  defp priority(_payload), do: []

  @doc """
  Where the button of the next action in `payload` leads: `{:ok, path}` for a
  redirect, else `:error`.
  """
  def target(%{"action_module" => module_string, "params" => params}) do
    with {:ok, action_module} <- resolve_module(module_string),
         %{cta_action: %{type: :redirect, to: to}} <- action_module.to_view_model(1, params) do
      {:ok, to}
    else
      _ -> :error
    end
  end

  def target(_payload), do: :error

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
  # Clears only the next action this message created: a next action created
  # again since then, for a newer message with the same key, stays.
  def mark_seen(%MessageModel{id: message_id, event_id: event_id, payload: payload}) do
    with {:ok, event} <- fetch_event(event_id),
         {:ok, user} <- fetch_user(event.subject_user_id),
         {:ok, action_module} <- resolve_module(payload["action_module"]) do
      NextAction.Public.clear_next_action(user, action_module,
        key: payload["key"],
        params: %{"notify_message_id" => message_id}
      )

      :ok
    end
  end
end
