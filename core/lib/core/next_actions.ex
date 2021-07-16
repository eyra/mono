defmodule Core.NextActions do
  @moduledoc """
  The NextActions context.
  """

  import Ecto.Query, warn: false
  alias Core.Repo
  alias Core.Accounts.User

  alias Core.NextActions.NextAction

  @doc """
  """
  def list_next_actions(%User{} = user, content_node \\ nil) do
    from(na in NextAction, where: na.user_id == ^user.id, limit: 10)
    |> filter_by_content_node(content_node)
    |> Repo.all()
  end

  @doc """
  Creates a next action.
  """
  def create_next_action(%User{} = user, action, opts \\ []) when is_atom(action) do
    content_node = Keyword.get(opts, :content_node)

    conflict_target_fragment =
      if is_nil(content_node) do
        "(user_id,action) WHERE content_node_id is NULL"
      else
        "(user_id,action,content_node_id) WHERE content_node_id is not NULL"
      end

    %NextAction{}
    |> NextAction.changeset(%{
      user: user,
      action: Atom.to_string(action),
      content_node: content_node,
      params: Keyword.get(opts, :params)
    })
    |> Repo.insert!(
      on_conflict: [inc: [count: 1]],
      conflict_target: {:unsafe_fragment, conflict_target_fragment}
    )
  end

  def clear_next_action(user, action, content_node \\ nil) do
    action_string = to_string(action)

    from(na in NextAction, where: na.user_id == ^user.id and na.action == ^action_string)
    |> filter_by_content_node(content_node)
    |> Repo.delete_all()
  end

  def to_view_model(socket, %NextAction{action: action, count: count, params: params}) do
    action_type = String.to_existing_atom(action)
    apply(action_type, :to_view_model, [socket, count, params])
  end

  defp filter_by_content_node(query, content_node) when is_nil(content_node), do: query

  defp filter_by_content_node(query, content_node) do
    where(query, [na], na.content_node_id == ^content_node.id)
  end
end
