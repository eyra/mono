defmodule Systems.Org.NodeModel do
  use Ecto.Schema
  import Ecto.Changeset

  use Systems.{
    Org.Internals
  }

  alias Systems.{
    Content
  }

  schema "org_nodes" do
    field(:type, Ecto.Enum, values: Types.schema_values())
    field(:identifier, {:array, :string})

    belongs_to(:short_name_bundle, Content.TextBundleModel)
    belongs_to(:full_name_bundle, Content.TextBundleModel)

    many_to_many(:users, Node,
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

  @required_fields ~w(type identifier)a
  @optional_fields ~w()a
  @fields @required_fields ++ @optional_fields

  def preload_graph(:full) do
    [
      :users,
      :links,
      short_name_bundle: Content.TextBundleModel.preload_graph(:full),
      full_name_bundle: Content.TextBundleModel.preload_graph(:full)
    ]
  end

  def changeset(node, attrs) do
    node
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:identifier)
  end
end
