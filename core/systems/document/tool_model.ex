defmodule Systems.Document.ToolModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  import CoreWeb.Gettext

  schema "document_tools" do
    field(:name, :string)
    field(:ref, :string)
    field(:director, Ecto.Enum, values: [:assignment])
    belongs_to(:auth_node, Core.Authorization.Node)

    timestamps()
  end

  @fields ~w(name ref)a
  @required_fields @fields

  def changeset(model, params) do
    model
    |> cast(params, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def ready?(tool) do
    changeset =
      changeset(tool, %{})
      |> validate()

    changeset.valid?()
  end

  def preload_graph(:down), do: preload_graph([])

  defimpl Frameworks.Concept.ToolModel do
    alias Systems.Document
    def key(_), do: :document
    def auth_tree(%{auth_node: auth_node}), do: auth_node
    def apply_label(_), do: dgettext("eyra-document", "apply.cta.title")
    def open_label(_), do: dgettext("eyra-document", "open.cta.title")
    def ready?(tool), do: Document.ToolModel.ready?(tool)
    def form(_), do: Document.ToolForm

    def launcher(%{ref: ref}),
      do: %{
        module: Document.PDFView,
        params: %{
          url: ref,
          title: dgettext("eyra-document", "component.title")
        }
      }

    def task_labels(_) do
      %{
        pending: dgettext("eyra-document", "pending.label"),
        participated: dgettext("eyra-document", "participated.label")
      }
    end

    def attention_list_enabled?(_t), do: false
    def group_enabled?(_t), do: true
  end

  defimpl Frameworks.Concept.Directable do
    def director(%{director: director}), do: Frameworks.Utility.Module.get(director, "Director")
  end
end
