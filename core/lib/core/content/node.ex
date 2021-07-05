defmodule Core.Content.Node do
  @moduledoc """
  The content node schema.
  """
  use Ecto.Schema
  require Core.Themes
  import Ecto.Changeset

  schema "content_nodes" do
    field(:ready, :boolean)
    field(:parent_id, :integer)

    belongs_to(:parent, __MODULE__, foreign_key: :parent_id, references: :id, define_field: false)
    has_many(:children, __MODULE__, foreign_key: :parent_id, references: :id)

    timestamps()
  end

  @fields ~w(ready parent_id)a
  @required_fields ~w(ready)a

  @doc false
  def changeset(node, attrs) do
    node
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  @callback operational_fields() :: list(atom())

  defmacro __using__(_opts) do
    quote do
      @behaviour Core.Content.Node

      import Ecto.Changeset

      alias Core.Content.Node
      alias Core.Repo

      def ready?(node, attrs) do
        changeset =
          node
          |> cast(attrs, operational_fields())
          |> validate_required(operational_fields())

        changeset.valid?
      end

      def node_changeset(node, tool, attrs) do
        ready = ready?(tool, attrs)
        Node.changeset(node, %{ready: ready})
      end

      def save_node(changeset) do
        changeset
        |> Repo.update()
      end
    end
  end
end
