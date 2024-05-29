defmodule Systems.NextAction.Public do
  @moduledoc """
  The NextActions context.
  """

  import Ecto.Query, warn: false
  alias Core.Repo
  alias Systems.Account.User
  alias Frameworks.Signal

  alias Systems.NextAction

  @doc """
  """
  def count_next_actions(%User{} = user) do
    from(na in NextAction.Model, where: na.user_id == ^user.id, select: count("*"))
    |> Repo.one()
  end

  @doc """
  """
  def list_next_actions(%User{} = user) do
    from(na in NextAction.Model, where: na.user_id == ^user.id, limit: 10)
    |> Repo.all()
    |> Enum.map(&to_view_model(&1))
  end

  @doc """
  """
  def next_best_action(%User{} = user) do
    from(na in NextAction.Model, where: na.user_id == ^user.id, limit: 1)
    |> Repo.one()
    |> to_view_model()
  end

  @doc """
  """
  def next_best_action!(%User{} = user) do
    list_next_actions(user)
    |> List.first()
  end

  @doc """
  Creates a next action for the audience.
  """
  def create_next_action(audience, action, opts \\ [])

  def create_next_action([_ | _] = users, action, opts) when is_atom(action) do
    Enum.map(users, &create_next_action(&1, action, opts))
  end

  def create_next_action(%User{} = user, action, opts) when is_atom(action) do
    key = Keyword.get(opts, :key)

    conflict_target_fragment =
      if is_nil(key) do
        "(user_id,action) WHERE key is NULL"
      else
        "(user_id,action,key) WHERE key is not NULL"
      end

    %NextAction.Model{}
    |> NextAction.Model.changeset(%{
      user: user,
      action: Atom.to_string(action),
      key: key,
      params: Keyword.get(opts, :params)
    })
    |> Repo.insert!(
      on_conflict: [inc: [count: 1]],
      conflict_target: {:unsafe_fragment, conflict_target_fragment}
    )
    |> tap(
      &Signal.Public.dispatch!({:next_action, :created}, %{
        action_type: action,
        user: user,
        action: &1,
        key: key
      })
    )
  end

  def clear_next_action(audience, action, opts \\ [])

  def clear_next_action([_ | _] = users, action, opts) do
    Enum.map(users, &clear_next_action(&1, action, opts))
  end

  def clear_next_action(user, action, opts) do
    key = Keyword.get(opts, :key)
    action_string = to_string(action)

    from(na in NextAction.Model, where: na.user_id == ^user.id and na.action == ^action_string)
    |> where_key_is(key)
    |> Repo.delete_all()
    |> tap(fn _ ->
      Signal.Public.dispatch!({:next_action, :cleared}, %{
        user: user,
        action_type: action,
        key: key
      })
    end)
  end

  defp where_key_is(query, nil), do: from(na in query, where: is_nil(na.key))
  defp where_key_is(query, key), do: from(na in query, where: na.key == ^key)

  def to_view_model(nil), do: nil

  def to_view_model(%NextAction.Model{action: action, count: count, params: params}) do
    action_type = String.to_existing_atom(action)

    action_type
    |> apply(:to_view_model, [count, params])
    |> Map.put(:action_type, action_type)
  end
end
