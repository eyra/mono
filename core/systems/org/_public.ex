defmodule Systems.Org.Public do
  @moduledoc false
  use Core, :public
  use Systems.Org.Internals

  import Ecto.Query, warn: false

  alias Core.Repo
  alias Ecto.Multi
  alias Systems.Account.User
  alias Systems.Content

  def get_node([_ | _] = identifier, preload \\ []) do
    Repo.one(from(node in Node, where: node.identifier == ^identifier, preload: ^preload))
  end

  def get_node!(id, preload \\ [])

  def get_node!([_ | _] = identifier, preload) do
    Repo.one!(from(node in Node, where: node.identifier == ^identifier, preload: ^preload))
  end

  def get_node!(id, preload) do
    Repo.get!(from(node in Node, preload: ^preload), id)
  end

  def create_node!(type, identifier, short_name, full_name) do
    case create_node(type, identifier, short_name, full_name) do
      {:ok, %{org: org}} -> org
      _ -> nil
    end
  end

  def create_node(type, identifier, short_name, full_name) do
    Multi.new()
    |> Multi.run(:short_name, fn _, _ ->
      {:ok, %{bundle: bundle}} = Content.Public.create_text_bundle(short_name)
      {:ok, bundle}
    end)
    |> Multi.run(:full_name, fn _, _ ->
      {:ok, %{bundle: bundle}} = Content.Public.create_text_bundle(full_name)
      {:ok, bundle}
    end)
    |> Multi.run(:org, fn _, %{short_name: short_name, full_name: full_name} ->
      {
        :ok,
        Org.Public.create_node!(%{
          type: type,
          identifier: identifier,
          short_name_bundle: short_name,
          full_name_bundle: full_name
        })
      }
    end)
    |> Repo.commit()
  end

  def create_node!(%{} = attrs) do
    {short_name_bundle, attrs} = Map.pop(attrs, :short_name_bundle, nil)
    {full_name_bundle, attrs} = Map.pop(attrs, :full_name_bundle, nil)

    attrs
    |> Node.create(short_name_bundle, full_name_bundle)
    |> Repo.insert!()
  end

  def get_link(%Node{id: from_id}, %Node{id: to_id}, preload \\ []) do
    Repo.one(from(link in Link, where: link.from_id == ^from_id, where: link.to_id == ^to_id, preload: ^preload))
  end

  def create_link!(%Node{} = from, %Node{} = to) do
    %Link{}
    |> Link.changeset(%{})
    |> Ecto.Changeset.put_assoc(:from, from)
    |> Ecto.Changeset.put_assoc(:to, to)
    |> Repo.insert!()
  end

  def add_user([_ | _] = identifier, %User{} = user) do
    identifier
    |> get_node!()
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
    identifier
    |> get_node!()
    |> delete_user(user)
  end

  def delete_user(%Node{} = node, %User{} = user) do
    Repo.delete_all(from(ua in UserAssociation, where: ua.org_id == ^node.id, where: ua.user_id == ^user.id))
  end

  def list_nodes(preload) do
    preload
    |> list_nodes_query()
    |> Repo.all()
  end

  def list_nodes(_, preload)

  def list_nodes(%User{} = user, preload) do
    user
    |> list_nodes_query(preload)
    |> Repo.all()
  end

  def list_nodes(type, preload) when is_atom(type) do
    type
    |> list_nodes_query(preload)
    |> Repo.all()
  end

  def list_nodes(_, _, preload)

  def list_nodes(%User{} = user, type, preload) when is_atom(type) do
    user
    |> list_nodes_query(type, preload)
    |> Repo.all()
  end

  def list_nodes(type, identifier_template, preload) when is_list(identifier_template) do
    type
    |> list_nodes_query(identifier_template, preload)
    |> Repo.all()
  end

  def list_nodes(type, _, preload) do
    type
    |> list_nodes_query(preload)
    |> Repo.all()
  end

  defp list_nodes_query(preload) do
    query_preload(from(node in Node), preload)
  end

  defp list_nodes_query(%User{} = user, type, preload) when is_atom(type) do
    subquery = list_nodes_query(user, preload)

    from(node in subquery,
      where: node.type == ^type
    )
  end

  defp list_nodes_query(type, identifier_template, preload) when is_list(identifier_template) do
    subquery = list_nodes_query(type, preload)

    from(node in subquery,
      where: fragment("?::text[] @> ?", node.identifier, ^identifier_template)
    )
  end

  defp list_nodes_query(%User{} = user, preload) do
    query_preload(
      from(node in Node,
        inner_join: ua in UserAssociation,
        on: ua.org_id == node.id,
        inner_join: u in User,
        on: u.id == ua.user_id,
        where: u.id == ^user.id
      ),
      preload
    )
  end

  defp list_nodes_query(type, preload) when is_atom(type) do
    query_preload(from(node in Node, where: node.type == ^type), preload)
  end

  defp query_preload(query, preload) when is_list(preload) do
    from(node in query, preload: ^preload)
  end

  defp query_preload(query, _), do: query_preload(query, [])
end
