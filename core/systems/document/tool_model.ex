defmodule Systems.Document.ToolModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Workflow

  @tool_directors Application.compile_env(:core, :tool_directors)

  schema "document_tools" do
    field(:name, :string)
    field(:ref, :string)
    field(:director, Ecto.Enum, values: @tool_directors)
    belongs_to(:auth_node, Core.Authorization.Node)

    has_one(:tool_ref, Workflow.ToolRefModel, foreign_key: :document_tool_id)

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
    use Gettext, backend: CoreWeb.Gettext

    alias Systems.Document
    def key(_), do: :document
    def auth_tree(%{auth_node: auth_node}), do: auth_node
    def apply_label(_), do: dgettext("eyra-document", "apply.cta.title")
    def open_label(_), do: dgettext("eyra-document", "open.cta.title")
    def ready?(tool), do: Document.ToolModel.ready?(tool)
    def form(_, _), do: Document.ToolForm

    def launcher(%{id: id, ref: ref}),
      do: %{
        module: Document.PDFNavView,
        params: %{
          key: "pdf_view_#{id}",
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
