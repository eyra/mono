defmodule Core.Content.Node do
  @moduledoc """
  The content node schema.
  """
  use Ecto.Schema
  require Core.Enums.Themes
  import Ecto.Changeset

  schema "content_nodes" do
    field(:ready, :boolean)
    field(:parent_id, :integer)

    belongs_to(:parent, __MODULE__, foreign_key: :parent_id, references: :id, define_field: false)
    has_many(:children, __MODULE__, foreign_key: :parent_id, references: :id)

    timestamps()
  end

  @fields ~w(ready)a
  @required_fields ~w(ready)a

  @doc false
  def changeset(node, attrs) do
    node
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  @callback operational_fields() :: list(atom())
  @callback operational_validation(Ecto.Changeset.t()) :: Ecto.Changeset.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour Core.Content.Node

      import Ecto.Changeset

      alias Core.Content.Node
      alias Core.Repo

      def ready?(entity, attrs) do
        changeset = operational_changeset(entity, attrs)
        changeset.valid?
      end

      def operational_changeset(entity, attrs) do
        changeset =
          entity
          |> cast(attrs, operational_fields())
          |> validate_required(operational_fields())
          |> operational_validation()
      end

      def node_changeset(node, entity, attrs) do
        ready = ready?(entity, attrs)
        Node.changeset(node, %{ready: ready})
      end
    end
  end
end
