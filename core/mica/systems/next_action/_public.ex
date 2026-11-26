defmodule Systems.NextAction.Public do
  @moduledoc """
  The NextActions context.
  """
  # This is a macro that imports the Mica module and the public macro from the Mica module.
  use Mica, :public
  require Logger
  import Ecto.Query, warn: false
  alias Mica.Repo
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
    |> by_priority()
    |> Repo.all()
    |> view_models()
  end

  @doc """
  """
  def next_best_action(%User{} = user) do
    from(na in NextAction.Model, where: na.user_id == ^user.id)
    |> by_priority()
    |> Repo.all()
    |> Enum.find_value(&to_view_model/1)
  end

  @doc """
  """
  def next_best_action!(%User{} = user) do
    list_next_actions(user)
    |> List.first()
  end

  @doc """
  Returns the next action for a specific key.
  """
  def next_best_action_for_key(%User{id: user_id}, key) do
    from(na in NextAction.Model, where: na.user_id == ^user_id and na.key == ^key, limit: 1)
    |> by_priority()
    |> Repo.one()
    |> to_view_model()
  end

  @doc """
  Returns the top next action for a user, scoped to a specific action module
  and a set of key values (typically ids of the scoping object — assignments
  in a project, pools in an org, etc.). Returns `nil` when nothing matches.
  """
  def next_best_action_for_scope(%User{id: user_id}, action, scope_ids)
      when is_atom(action) and is_list(scope_ids) do
    action_string = to_string(action)
    keys = Enum.map(scope_ids, &to_string/1)

    from(na in NextAction.Model,
      where: na.user_id == ^user_id and na.action == ^action_string and na.key in ^keys,
      limit: 1
    )
    |> by_priority()
    |> Repo.one()
    |> to_view_model()
  end

  @doc """
  Lists all next actions of a specific type for a user.
  """
  def list_next_actions_by_type(%User{id: user_id}, action_type) when is_atom(action_type) do
    action_string = to_string(action_type)

    from(na in NextAction.Model,
      where: na.user_id == ^user_id and na.action == ^action_string,
      limit: 10
    )
    |> by_priority()
    |> Repo.all()
    |> view_models()
  end

  @doc """
  Creates a next action for the audience.

  Options:
    * `:key` - distinguishes several next actions of the same type for one user
    * `:params` - passed to the action's `to_view_model/2`
    * `:priority` - `:high`, `:normal` (default) or `:low`; lists show higher
      priorities first. Creating an existing next action again increases its
      count and only changes its priority when `:priority` is given. Leave the
      option out instead of passing `nil`, which the changeset refuses.
  """
  def create_next_action(audience, action, opts \\ [])

  def create_next_action([_ | _] = users, action, opts) when is_atom(action) do
    Enum.map(users, &create_next_action(&1, action, opts))
  end

  def create_next_action(%User{} = user, action, opts) when is_atom(action) do
    key = Keyword.get(opts, :key)
    priority_attrs = Map.new(Keyword.take(opts, [:priority]))

    %NextAction.Model{}
    |> NextAction.Model.changeset(
      Map.merge(
        %{
          user: user,
          action: Atom.to_string(action),
          key: key,
          params: Keyword.get(opts, :params)
        },
        priority_attrs
      )
    )
    |> Repo.insert!(
      on_conflict: [inc: [count: 1], set: Map.to_list(priority_attrs)],
      conflict_target: {:unsafe_fragment, conflict_target_fragment(key)}
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

  @batch_size 1_000

  @doc """
  Creates the same next action for every user in `user_ids` with batched
  inserts, for audiences too large for `create_next_action/3`. Takes the same
  options. Users who already have it get its count increased, as with
  `create_next_action/3`.

  No `{:next_action, :created}` signal is sent: open pages and menu counters
  show the new next actions on their next load. Returns the number of rows
  inserted or updated.
  """
  def create_next_actions(user_ids, action, opts \\ [])
      when is_list(user_ids) and is_atom(action) do
    key = Keyword.get(opts, :key)
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    priority_attrs = Keyword.take(opts, [:priority])

    row = %{
      action: Atom.to_string(action),
      key: key,
      params: Keyword.get(opts, :params),
      count: 1,
      priority: Keyword.get(opts, :priority, :normal),
      inserted_at: now,
      updated_at: now
    }

    user_ids
    |> Enum.uniq()
    |> Enum.chunk_every(@batch_size)
    |> Enum.reduce(0, fn chunk, total ->
      rows = Enum.map(chunk, &Map.put(row, :user_id, &1))

      {count, _} =
        Repo.insert_all(NextAction.Model, rows,
          on_conflict: [inc: [count: 1], set: [updated_at: now] ++ priority_attrs],
          conflict_target: {:unsafe_fragment, conflict_target_fragment(key)}
        )

      total + count
    end)
  end

  defp conflict_target_fragment(nil), do: "(user_id,action) WHERE key is NULL"
  defp conflict_target_fragment(_key), do: "(user_id,action,key) WHERE key is not NULL"

  @doc """
  Clears the next action of type `action` of the audience.

  Options:
    * `:key` - the key it was created with
    * `:params` - only a next action whose params hold these values, or don't
      hold such a param at all (one stored before it was). Clears nothing that
      was created again for something else in the meantime.
  """
  def clear_next_action(audience, action, opts \\ [])

  def clear_next_action([_ | _] = users, action, opts) do
    Enum.map(users, &clear_next_action(&1, action, opts))
  end

  def clear_next_action(user, action, opts) do
    key = Keyword.get(opts, :key)
    action_string = to_string(action)

    from(na in NextAction.Model, where: na.user_id == ^user.id and na.action == ^action_string)
    |> where_key_is(key)
    |> where_params(Keyword.get(opts, :params, %{}))
    |> Repo.delete_all()
    |> tap(fn _ ->
      Signal.Public.dispatch!({:next_action, :cleared}, %{
        user: user,
        action_type: action,
        key: key
      })
    end)
  end

  defp by_priority(query) do
    from(na in query,
      order_by: [desc: na.priority, desc: na.inserted_at, asc: na.action, asc: na.key]
    )
  end

  defp where_key_is(query, nil), do: from(na in query, where: is_nil(na.key))
  defp where_key_is(query, key), do: from(na in query, where: na.key == ^key)

  # A row whose params hold each value, or don't hold that param at all (a row
  # stored before the param was).
  defp where_params(query, params) do
    Enum.reduce(params, query, fn {name, value}, query ->
      value = to_string(value)

      from(na in query,
        where: fragment("coalesce(? ->> ?, ?) = ?", na.params, ^name, ^value, ^value)
      )
    end)
  end

  defp view_models(next_actions), do: Enum.flat_map(next_actions, &List.wrap(to_view_model(&1)))

  @doc """
  The view model of a stored next action, or `nil`. A next action whose type
  this release doesn't have (stored by a later release, before a rollback or
  during a rolling deploy) is `nil` too, so lists leave it out instead of
  failing.
  """
  def to_view_model(nil), do: nil

  def to_view_model(%NextAction.Model{action: action, count: count, params: params}) do
    case action_type(action) do
      {:ok, action_type} ->
        action_type.to_view_model(count, params)
        |> Map.put(:action_type, action_type)

      :error ->
        Logger.warning("[NextAction] skipped next action of unknown type #{action}")
        nil
    end
  end

  defp action_type(action) do
    action_type = String.to_existing_atom(action)

    if Code.ensure_loaded?(action_type) and function_exported?(action_type, :to_view_model, 2),
      do: {:ok, action_type},
      else: :error
  rescue
    ArgumentError -> :error
  end
end
