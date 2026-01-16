defmodule Systems.Org.NodeModel do
  use Ecto.Schema
  import Ecto.Changeset
  import Frameworks.Utility.EctoHelper, only: [apply_virtual_change: 4]

  alias Systems.Account.User

  use Systems.{
    Org.Internals
  }

  alias Systems.{
    Content
  }

  schema "org_nodes" do
    field(:identifier, {:array, :string})
    field(:identifier_string, :string, virtual: true)
    field(:domains, {:array, :string})
    field(:domains_string, :string, virtual: true)
    field(:archived_at, :utc_datetime)

    belongs_to(:auth_node, Core.Authorization.Node)
    belongs_to(:short_name_bundle, Content.TextBundleModel, on_replace: :update)
    belongs_to(:full_name_bundle, Content.TextBundleModel, on_replace: :update)

    many_to_many(:users, User,
      join_through: Org.UserAssociation,
      join_keys: [org_id: :id, user_id: :id]
    )

    many_to_many(
      :links,
      Node,
      join_through: Link,
      join_keys: [from_id: :id, to_id: :id]
    )

    many_to_many(
      :reverse_links,
      Node,
      join_through: Link,
      join_keys: [to_id: :id, from_id: :id]
    )

    timestamps()
  end

  @fields ~w(identifier identifier_string domains_string)a
  @required_fields ~w(identifier)a

  def preload_graph(:full) do
    [
      :users,
      :links,
      :reverse_links,
      :auth_node,
      short_name_bundle: Content.TextBundleModel.preload_graph(:full),
      full_name_bundle: Content.TextBundleModel.preload_graph(:full)
    ]
  end

  def create(attrs, short_name_bundle, full_name_bundle, auth_node \\ nil) do
    %Node{}
    |> Ecto.Changeset.cast(attrs, [:identifier])
    |> Ecto.Changeset.unique_constraint(:identifier)
    |> Ecto.Changeset.put_assoc(:short_name_bundle, short_name_bundle)
    |> Ecto.Changeset.put_assoc(:full_name_bundle, full_name_bundle)
    |> maybe_put_auth_node(auth_node)
  end

  defp maybe_put_auth_node(changeset, nil), do: changeset

  defp maybe_put_auth_node(changeset, auth_node) do
    Ecto.Changeset.put_assoc(changeset, :auth_node, auth_node)
  end

  def changeset(node, attrs) do
    node
    |> prepare_virtual()
    |> cast(attrs, @fields)
    |> apply_text_bundle_changes(attrs, :full_name_bundle)
    |> apply_text_bundle_changes(attrs, :short_name_bundle)
    |> apply_virtual_changes()
    |> validate_required(@required_fields)
    |> unique_constraint(:identifier)
  end

  defp prepare_virtual(%{identifier: identifier, domains: domains} = node) do
    %{
      node
      | identifier_string: to_string(identifier, "_"),
        domains_string: to_string(domains, " ")
    }
  end

  defp apply_text_bundle_changes(changeset, attrs, field) do
    Content.TextBundleModel.apply_text_bundle_changes(changeset, attrs, field)
  end

  defp to_string(nil, _delimiter), do: ""
  defp to_string(field, delimiter), do: field |> Enum.join(delimiter)

  defp apply_virtual_changes(changeset) do
    changeset
    |> apply_virtual_change(:identifier, :identifier_string, ["_"])
    |> apply_virtual_change(:domains, :domains_string, [" ", ","])
  end

  def archived?(%{archived_at: nil}), do: false
  def archived?(%{archived_at: _}), do: true

  def archive_changeset(node) do
    node
    |> change(%{archived_at: DateTime.utc_now() |> DateTime.truncate(:second)})
  end

  def restore_changeset(node) do
    node
    |> change(%{archived_at: nil})
  end

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(org_node), do: org_node.auth_node_id
  end
end
