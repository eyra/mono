defmodule Core.NextActions do
  @moduledoc """
  The NextActions context.
  """

  import Ecto.Query, warn: false
  alias Core.Repo
  alias Core.Accounts.User
  alias Core.Signals

  alias Core.NextActions.NextAction

  @doc """
  """
  def count_next_actions(%User{} = user) do
    from(na in NextAction, where: na.user_id == ^user.id, select: count("*"))
    |> Repo.one()
  end

  @doc """
  """
  def list_next_actions(url_resolver, %User{} = user, content_node \\ nil)
      when is_function(url_resolver) do
    from(na in NextAction, where: na.user_id == ^user.id, limit: 10)
    |> filter_by_content_node(content_node)
    |> Repo.all()
    |> Enum.map(&to_view_model(&1, url_resolver))
  end

  @doc """
  """
  def next_best_action(url_resolver, %User{} = user, content_node \\ nil)
      when is_function(url_resolver) do
    from(na in NextAction, where: na.user_id == ^user.id, limit: 1)
    |> filter_by_content_node(content_node)
    |> Repo.one()
    |> to_view_model(url_resolver)
  end

  @doc """
  """
  def next_best_action!(url_resolver, %User{} = user, content_node \\ nil)
      when is_function(url_resolver) do
    list_next_actions(url_resolver, user, content_node)
    |> List.first()
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
    |> tap(
      &Signals.dispatch!(:next_action_created, %{action_type: action, user: user, action: &1})
    )
  end

  def clear_next_action(user, action, content_node \\ nil) do
    action_string = to_string(action)

    from(na in NextAction, where: na.user_id == ^user.id and na.action == ^action_string)
    |> filter_by_content_node(content_node)
    |> Repo.delete_all()
    |> tap(fn _ -> Signals.dispatch!(:next_action_cleared, %{user: user, action_type: action}) end)
  end

  def to_view_model(nil, _url_resolver), do: nil

  def to_view_model(%NextAction{action: action, count: count, params: params}, url_resolver) do
    action_type = String.to_existing_atom(action)

    action_type
    |> apply(:to_view_model, [url_resolver, count, params])
    |> Map.put(:action_type, action_type)
  end

  defp filter_by_content_node(query, content_node) when is_nil(content_node), do: query

  defp filter_by_content_node(query, content_node) do
    where(query, [na], na.content_node_id == ^content_node.id)
  end
end
