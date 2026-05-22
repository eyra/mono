defmodule Systems.Admin.Public do
  use Core, :public

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
end
