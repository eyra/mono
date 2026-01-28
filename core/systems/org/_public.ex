defmodule Systems.Org.Public do
  use Core, :public
  import Ecto.Query, warn: false

  alias Core.Repo
  alias Systems.Account.User
  alias Ecto.Multi

  use Systems.{
    Org.Internals
  }

  alias Systems.{
    Content
  }

  def get_node([_ | _] = identifier, preload \\ []) do
    from(node in Node,
      where: node.identifier == ^identifier,
      preload: ^preload
    )
    |> Repo.one()
  end

  def get_node!(id, preload \\ [])

  def get_node!([_ | _] = identifier, preload) do
    from(node in Node,
      where: node.identifier == ^identifier,
      preload: ^preload
    )
    |> Repo.one!()
  end

  def get_node!(id, preload) do
    from(node in Node, preload: ^preload)
    |> Repo.get!(id)
  end

  def create_node!(identifier, short_name, full_name) do
    case create_node(identifier, short_name, full_name) do
      {:ok, %{org: org}} -> org
      _ -> nil
    end
  end

  def create_node(identifier, short_name, full_name) do
    Multi.new()
    |> Multi.run(:short_name, fn _, _ ->
      {:ok, %{bundle: bundle}} = Content.Public.create_text_bundle(short_name)
      {:ok, bundle}
    end)
    |> Multi.run(:full_name, fn _, _ ->
      {:ok, %{bundle: bundle}} = Content.Public.create_text_bundle(full_name)
      {:ok, bundle}
    end)
    |> Multi.run(:auth_node, fn _, _ ->
      {:ok, auth_module().prepare_node() |> Repo.insert!()}
    end)
    |> Multi.run(:org, fn _,
                          %{short_name: short_name, full_name: full_name, auth_node: auth_node} ->
      {
        :ok,
        %{
          identifier: identifier,
          short_name_bundle: short_name,
          full_name_bundle: full_name,
          auth_node: auth_node
        }
        |> Org.Public.create_node!()
      }
    end)
    |> Repo.commit()
  end

  def create_node!(%{} = attrs) do
    {short_name_bundle, attrs} = Map.pop(attrs, :short_name_bundle, nil)
    {full_name_bundle, attrs} = Map.pop(attrs, :full_name_bundle, nil)
    {auth_node, attrs} = Map.pop(attrs, :auth_node, nil)

    Node.create(attrs, short_name_bundle, full_name_bundle, auth_node)
    |> Repo.insert!()
  end

  def get_link(%Node{id: from_id}, %Node{id: to_id}, preload \\ []) do
    from(link in Link,
      where: link.from_id == ^from_id,
      where: link.to_id == ^to_id,
      preload: ^preload
    )
    |> Repo.one()
  end

  def create_link!(%Node{} = from, %Node{} = to) do
    %Link{}
    |> Link.changeset(%{})
    |> Ecto.Changeset.put_assoc(:from, from)
    |> Ecto.Changeset.put_assoc(:to, to)
    |> Repo.insert!()
  end

  def add_user([_ | _] = identifier, %User{} = user) do
    get_node!(identifier)
    |> add_user(user)
  end

  def add_user(%Node{} = node, %User{} = user) do
    %UserAssociation{}
    |> UserAssociation.changeset(node, user)
    |> Repo.insert!(
      on_conflict: :nothing,
      conflict_target: [:org_id, :user_id]
    )
  end

  def delete_user([_ | _] = identifier, %User{} = user) do
    get_node!(identifier)
    |> delete_user(user)
  end

  def delete_user(%Node{} = node, %User{} = user) do
    from(ua in UserAssociation,
      where: ua.org_id == ^node.id,
      where: ua.user_id == ^user.id
    )
    |> Repo.delete_all()
  end

  def list_nodes(preload) do
    list_nodes_query(preload)
    |> exclude_archived()
    |> Repo.all()
  end

  def list_nodes(%User{} = user, preload) do
    list_nodes_query(user, preload)
    |> exclude_archived()
    |> Repo.all()
  end

  def list_nodes(identifier_template, preload) when is_list(identifier_template) do
    list_nodes_query(identifier_template, preload)
    |> exclude_archived()
    |> Repo.all()
  end

  @doc """
  Lists all nodes including archived ones. Use sparingly.
  """
  def list_all_nodes(preload) do
    list_nodes_query(preload)
    |> Repo.all()
  end

  defp list_nodes_query(preload) do
    from(node in Node)
    |> query_preload(preload)
  end

  defp list_nodes_query(identifier_template, preload) when is_list(identifier_template) do
    from(node in Node,
      where: fragment("?::text[] @> ?", node.identifier, ^identifier_template)
    )
    |> query_preload(preload)
  end

  defp list_nodes_query(%User{} = user, preload) do
    from(node in Node,
      inner_join: ua in UserAssociation,
      on: ua.org_id == node.id,
      inner_join: u in User,
      on: u.id == ua.user_id,
      where: u.id == ^user.id
    )
    |> query_preload(preload)
  end

  defp query_preload(query, preload) when is_list(preload) do
    from(node in query, preload: ^preload)
  end

  defp query_preload(query, _), do: query_preload(query, [])

  defp exclude_archived(query) do
    from(node in query, where: is_nil(node.archived_at))
  end

  @doc """
  Lists only archived organisation nodes.
  """
  def list_archived_nodes(preload) do
    list_nodes_query(preload)
    |> only_archived()
    |> Repo.all()
  end

  defp only_archived(query) do
    from(node in query, where: not is_nil(node.archived_at))
  end

  @doc """
  Archives an organisation node.
  """
  def archive(%Node{} = node) do
    result =
      node
      |> Node.archive_changeset()
      |> Repo.update()

    case result do
      {:ok, archived_node} ->
        Frameworks.Signal.Public.dispatch!({:org_node, :archived}, %{
          org_node: archived_node,
          from_pid: self()
        })

        {:ok, archived_node}

      error ->
        error
    end
  end

  @doc """
  Restores an archived organisation node.
  """
  def restore(%Node{} = node) do
    result =
      node
      |> Node.restore_changeset()
      |> Repo.update()

    case result do
      {:ok, restored_node} ->
        Frameworks.Signal.Public.dispatch!({:org_node, :restored}, %{
          org_node: restored_node,
          from_pid: self()
        })

        {:ok, restored_node}

      error ->
        error
    end
  end

  # Owner role management

  @doc """
  Assigns the :owner role to a user for the given organisation.
  """
  def assign_owner(%Node{} = org, %User{} = user) do
    auth_module().assign_role(user, org, :owner)
  end

  @doc """
  Revokes the :owner role from a user for the given organisation.
  """
  def revoke_owner(%Node{} = org, %User{} = user) do
    auth_module().remove_role!(user, org, :owner)
  end

  @doc """
  Lists all users with the :owner role for the given organisation.
  """
  def list_owners(%Node{auth_node_id: nil}), do: []

  def list_owners(%Node{} = org) do
    auth_module().list_principals(org)
    |> Enum.filter(fn %{roles: roles} -> :owner in roles end)
    |> Enum.map(fn %{id: user_id} -> Repo.get!(User, user_id) end)
  end

  @doc """
  Lists all organisations where the user has the :owner role.
  """
  def list_orgs(%User{} = user, preload \\ []) do
    node_ids = auth_module().query_node_ids(role: :owner, principal: user)

    from(node in Node,
      where: node.auth_node_id in subquery(node_ids),
      preload: ^preload
    )
    |> Repo.all()
  end

  @doc """
  Checks if the user owns any organisations.
  """
  def owns_any?(%User{} = user) do
    node_ids = auth_module().query_node_ids(role: :owner, principal: user)

    from(node in Node,
      where: node.auth_node_id in subquery(node_ids)
    )
    |> Repo.exists?()
  end

  def owns_any?(_), do: false

  @doc """
  Finds platform users whose email matches org domains but aren't already members.
  Returns users that could be suggested for membership based on email domain matching.
  """
  def find_domain_matched_users(nil, _current_members), do: []
  def find_domain_matched_users([], _current_members), do: []

  def find_domain_matched_users(domains, current_members) when is_list(domains) do
    current_member_ids = Enum.map(current_members, & &1.id)
    domain_patterns = Enum.map(domains, &"%@#{&1}")

    from(user in User,
      where: fragment("? ILIKE ANY(?)", user.email, ^domain_patterns),
      where: user.id not in ^current_member_ids
    )
    |> Repo.all()
  end

  # Member role management (Option C pattern - auth roles as source of truth)

  @doc """
  Lists all users with the :member role for the given organisation.
  Auth roles are the source of truth for membership (Option C pattern).
  """
  def list_members(%Node{auth_node_id: nil}), do: []

  def list_members(%Node{} = org) do
    auth_module().list_principals(org)
    |> Enum.filter(fn %{roles: roles} -> :member in roles end)
    |> Enum.map(fn %{id: user_id} -> Repo.get!(User, user_id) end)
  end

  @doc """
  Assigns the :member role to a user for the given organisation.
  Auth roles are the source of truth for membership (Option C pattern).
  """
  def add_member(%Node{} = org, %User{} = user) do
    auth_module().assign_role(user, org, :member)
  end

  @doc """
  Revokes the :member role from a user for the given organisation.
  Auth roles are the source of truth for membership (Option C pattern).
  """
  def remove_member(%Node{} = org, %User{} = user) do
    auth_module().remove_role!(user, org, :member)
  end

  @doc """
  Checks if a user is a member of the given organisation.
  """
  def member?(%Node{} = org, %User{} = user) do
    list_members(org)
    |> Enum.any?(&(&1.id == user.id))
  end

  # NextAction sync for domain-matched users

  alias Systems.NextAction
  alias Systems.Org

  defp format_domains(nil), do: ""
  defp format_domains([]), do: ""
  defp format_domains(domains), do: Enum.join(domains, ", ")

  @doc """
  Syncs the NextAction for domain-matched users.
  Creates the action if domain-matched users exist, clears it otherwise.
  """
  def sync_domain_match_next_action(
        %Node{id: org_id, domains: domains, short_name_bundle: short_name_bundle} = node,
        %User{} = user,
        locale \\ :en
      ) do
    members = list_members(node)
    owners = list_owners(node)
    domain_matched = find_domain_matched_users(domains, members ++ owners)
    count = length(domain_matched)

    if count > 0 do
      org_name = Content.TextBundleModel.text(short_name_bundle, locale)
      domains_text = format_domains(domains)

      NextAction.Public.create_next_action(
        user,
        Org.NextActions.AddDomainMembers,
        key: "org:#{org_id}",
        params: %{org_id: org_id, org_name: org_name, domains: domains_text}
      )
    else
      NextAction.Public.clear_next_action(
        user,
        Org.NextActions.AddDomainMembers,
        key: "org:#{org_id}"
      )
    end
  end

  @doc """
  Syncs NextActions for all org owners when a new user registers.
  Finds orgs whose domains match the user's email and notifies their owners.
  """
  def sync_next_actions_for_new_user(%User{email: email}) do
    user_domain = extract_domain(email)

    list_nodes(Node.preload_graph(:full))
    |> Enum.filter(&domain_matches?(&1.domains, user_domain))
    |> Enum.each(fn org ->
      owners = list_owners(org)
      Enum.each(owners, &sync_domain_match_next_action(org, &1))
    end)
  end

  defp extract_domain(nil), do: nil

  defp extract_domain(email) when is_binary(email) do
    case String.split(email, "@") do
      [_, domain] -> String.downcase(domain)
      _ -> nil
    end
  end

  defp domain_matches?(nil, _user_domain), do: false
  defp domain_matches?([], _user_domain), do: false
  defp domain_matches?(_domains, nil), do: false

  defp domain_matches?(domains, user_domain) do
    Enum.any?(domains, &(String.downcase(&1) == user_domain))
  end

  alias Systems.Admin

  @doc """
  Syncs NextActions for a specific user across relevant orgs.
  For system admins: syncs all orgs.
  For org owners: syncs only orgs they own.
  Used as a fallback when opening admin pages.
  """
  def sync_all_domain_match_next_actions(%User{} = user) do
    is_admin? = Admin.Public.admin?(user)

    list_nodes(Node.preload_graph(:full))
    |> filter_orgs_for_user(user, is_admin?)
    |> Enum.each(&sync_domain_match_next_action(&1, user))
  end

  defp filter_orgs_for_user(orgs, _user, true), do: orgs

  defp filter_orgs_for_user(orgs, user, false) do
    Enum.filter(orgs, fn org -> user in list_owners(org) end)
  end
end
