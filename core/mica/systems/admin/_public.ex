defmodule Systems.Admin.Public do
  use Core, :public

  import Ecto.Query, warn: false

  alias Core.Repo
  alias Systems.Account
  alias Systems.Admin
  alias Systems.Assignment
  alias Systems.Org

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
    Application.get_env(:core, :admins, [])
  end

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
