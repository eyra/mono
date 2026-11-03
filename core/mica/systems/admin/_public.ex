defmodule Systems.Admin.Public do
  use Mica, :public

  import Ecto.Query, warn: false

  alias Mica.Repo
  alias Systems.Account
  alias Systems.Admin
  alias Systems.Affiliate
  alias Systems.Assignment
  alias Systems.Org
  alias Systems.Pool

  # Governable entity checkers - each returns true if user owns entities of that type
  # Add new entity types here as they become governable
  @governable_entity_checkers [
    &Org.Public.owns_any?/1
    # Future: &Pool.Public.owns_any?/1
  ]

  @doc """
  Checks if a user has access to admin features.

  A user has admin access if they are either:
  - A system admin (matches admin email patterns)
  - An owner of at least one governable entity (org, pool, etc.)
  """
  def admin_access?(user) do
    admin?(user) or has_governable_entities?(user)
  end

  @doc """
  Checks if a user owns any governable entities.

  Uses the configured list of entity checkers to determine if the user
  owns at least one entity of any governable type.
  """
  def has_governable_entities?(nil), do: false

  def has_governable_entities?(user) do
    Enum.any?(@governable_entity_checkers, fn checker -> checker.(user) end)
  end

  def compile(patterns) do
    combined =
      Enum.map_join(patterns, "|", fn pattern ->
        pattern
        |> Regex.escape()
        |> String.replace("\\*", "[\\w_\.\-]+")
      end)

    Regex.compile!("^#{combined}$")
  end

  def admin?(_compiled, email) when is_nil(email), do: false

  def admin?(%Regex{} = compiled, email) when is_binary(email) do
    Regex.match?(compiled, email)
  end

  def admin?([_ | _] = patterns, email) when is_binary(email) do
    admin?(compile(patterns), email)
  end

  def admin?(patterns, email) when is_list(patterns) do
    patterns
    |> compile()
    |> admin?(email)
  end

  def admin?(compiled, %{email: email}) do
    admin?(compiled, email)
  end

  def admin?(%{email: email}) do
    admin?(email)
  end

  def admin?(email) when is_binary(email) do
    admin?(email_patterns(), email)
  end

  def admin?(_), do: false

  defp email_patterns do
    Mica.Env.get(:admins, [])
  end

  # Users

  @doc """
  The users that match every filter in `filters` (`Systems.Admin.UserFilters`)
  and every word in `query` (in the email or full name, case-insensitive),
  sorted by label, with their profile preloaded. This is the matching of the
  Admin → Users tab.

  Filters combine with AND, so `:verified` together with `:unverified` matches
  nobody. A `nil` or empty query matches everyone. Affiliate and pool
  membership are looked up with one query per filter, not one per user.
  """
  def list_matching_users(filters, query) do
    Account.Public.list_users([:profile])
    |> Enum.sort(&(Account.User.label(&1) <= Account.User.label(&2)))
    |> filter_users(filters, build_filter_index(filters))
    |> filter_users(query)
  end

  defp build_filter_index(filters) do
    index = %{}

    index =
      if :affiliate in filters do
        Map.put(index, :affiliate_user_ids, MapSet.new(Affiliate.Public.list_user_ids()))
      else
        index
      end

    if :in_pool in filters do
      Map.put(index, :pool_user_ids, MapSet.new(Pool.Public.list_participant_ids()))
    else
      index
    end
  end

  defp filter_users(users, nil), do: users
  defp filter_users(users, []), do: users

  defp filter_users(users, query) when is_list(query) do
    Enum.filter(users, &matches?(&1, query))
  end

  defp filter_users(users, filters, index) when is_list(filters) do
    Enum.filter(users, &matches_filters?(&1, filters, index))
  end

  defp matches_filters?(_user, [], _index), do: true

  defp matches_filters?(user, [filter | rest], index),
    do: matches_filter?(user, filter, index) and matches_filters?(user, rest, index)

  defp matches_filter?(%Account.User{id: id}, :affiliate, %{affiliate_user_ids: ids}),
    do: MapSet.member?(ids, id)

  defp matches_filter?(%Account.User{id: id}, :in_pool, %{pool_user_ids: ids}),
    do: MapSet.member?(ids, id)

  defp matches_filter?(user, filter, _index) when is_atom(filter),
    do: matches_filter?(user, filter)

  defp matches_filter?(%Account.User{verified_at: verified_at}, :verified),
    do: verified_at != nil

  defp matches_filter?(%Account.User{verified_at: verified_at}, :unverified),
    do: verified_at == nil

  defp matches_filter?(%Account.User{creator: creator}, :creator) when not is_nil(creator),
    do: creator

  defp matches_filter?(%Account.User{}, :affiliate), do: false
  defp matches_filter?(%Account.User{}, :in_pool), do: false
  defp matches_filter?(_user, _filter), do: false

  defp matches?(_user, []), do: true

  defp matches?(user, [term | rest]),
    do: matches_word?(user, term) and matches?(user, rest)

  defp matches_word?(_user, ""), do: true

  defp matches_word?(%Account.User{email: email, profile: profile}, word) when is_binary(word) do
    word = String.downcase(word)
    String.contains?(String.downcase(email), word) or profile_matches?(profile, word)
  end

  defp matches_word?(_user, _word), do: false

  defp profile_matches?(%Account.UserProfileModel{fullname: fullname}, word)
       when not is_nil(fullname) do
    String.contains?(String.downcase(fullname), word)
  end

  defp profile_matches?(_profile, _word), do: false

  # Client activity

  @doc """
  Clients with the number of their project assignments under the given filters,
  ordered by assignment count (most first).
  """
  def list_client_activity(filters, %Date{} = today \\ Date.utc_today()) do
    Admin.Queries.client_assignment_query(filters, today)
    |> group_by([user: user], user.id)
    |> select([user: user, assignment: assignment], %{
      client: user,
      assignment_count: count(assignment.id)
    })
    |> order_by([user: user, assignment: assignment],
      desc: count(assignment.id),
      asc: user.email
    )
    |> Repo.all()
  end

  @doc """
  The client with the given id, or `nil`.
  """
  def get_client(client_id), do: Repo.get(Account.User, client_id)

  @doc """
  The project assignments of one client under the given filters, newest first.
  """
  def list_client_assignments(client_id, filters, %Date{} = today \\ Date.utc_today()) do
    Admin.Queries.client_assignment_query(filters, today)
    |> where([user: user], user.id == ^client_id)
    |> order_by([assignment: assignment], desc: assignment.inserted_at, desc: assignment.id)
    |> select([assignment: assignment, item: item], %{assignment: assignment, name: item.name})
    |> Repo.all()
  end

  @doc """
  One project assignment with its client and team (owners), or `nil`.
  """
  def get_client_assignment(assignment_id) when is_integer(assignment_id) do
    Admin.Queries.client_assignment_query([], Date.utc_today(), assignment_id)
    |> select([assignment: assignment, item: item, user: user], %{
      assignment: assignment,
      name: item.name,
      client: user
    })
    |> Repo.one()
    |> case do
      nil ->
        nil

      %{assignment: assignment} = result ->
        Map.put(result, :team, Assignment.Public.owners(assignment, [:profile]))
    end
  end
end
