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
    field(:type, Ecto.Enum, values: Types.schema_values())
    field(:type_string, :string, virtual: true)
    field(:identifier, {:array, :string})
    field(:identifier_string, :string, virtual: true)
    field(:domains, {:array, :string})
    field(:domains_string, :string, virtual: true)

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

  @fields ~w(type identifier identifier_string domains_string)a
  @required_fields ~w(type identifier)a

  def preload_graph(:full) do
    [
      :users,
      :links,
      short_name_bundle: Content.TextBundleModel.preload_graph(:full),
      full_name_bundle: Content.TextBundleModel.preload_graph(:full)
    ]
  end

  def create(attrs, short_name_bundle, full_name_bundle) do
    %Node{}
    |> Ecto.Changeset.cast(attrs, [:type, :identifier])
    |> Ecto.Changeset.unique_constraint(:identifier)
    |> Ecto.Changeset.put_assoc(:short_name_bundle, short_name_bundle)
    |> Ecto.Changeset.put_assoc(:full_name_bundle, full_name_bundle)
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

  defp prepare_virtual(%{identifier: identifier, domains: domains, type: type} = node) do
    %{
      node
      | type_string: Types.translate(type),
        identifier_string: to_string(identifier, "_"),
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
    |> apply_virtual_change(:type, :type_string, ["*"])
    |> apply_virtual_change(:identifier, :identifier_string, ["_"])
    |> apply_virtual_change(:domains, :domains_string, [" ", ","])
  end
end
