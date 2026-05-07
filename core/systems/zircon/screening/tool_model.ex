defmodule Systems.Zircon.Screening.ToolModel do
  use Gettext, backend: CoreWeb.Gettext

  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  alias Systems.Paper
  alias Systems.Zircon.Screening
  alias Systems.Annotation

  @tool_directors Application.compile_env(:core, :tool_directors)

  schema "zircon_screening_tool" do
    field(:director, Ecto.Enum, values: @tool_directors)

    belongs_to(:auth_node, Core.Authorization.Node)

    many_to_many(:reference_files, Paper.ReferenceFileModel,
      join_through: Screening.ToolReferenceFileAssoc,
      join_keys: [tool_id: :id, reference_file_id: :id]
    )

    many_to_many(:annotations, Annotation.Model,
      join_through: Screening.ToolAnnotationAssoc,
      join_keys: [tool_id: :id, annotation_id: :id]
    )

    timestamps()
  end

  @fields ~w(director)a
  @required_fields @fields

  def changeset(tool, attrs) do
    cast(tool, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: preload_graph([:auth_node, :reference_files])
  def preload_graph(:up), do: preload_graph([])
  def preload_graph(:auth_node), do: [auth_node: [:role_assignments]]

  def preload_graph(:reference_files),
    do: [reference_files: Paper.ReferenceFileModel.preload_graph(:down)]

  def preload_graph(:annotations),
    do: [annotations: Screening.ToolAnnotationAssoc.preload_graph(:down)]

  def ready?(%{name: nil}), do: false
  def ready?(%{image_id: nil}), do: false
  def ready?(%{papers: []}), do: false
  def ready?(%{criterion_groups: []}), do: false
  def ready?(_), do: true

  defimpl Frameworks.Concept.ToolModel do
    use Gettext, backend: CoreWeb.Gettext
    alias Systems.Zircon

    def key(_), do: :zircon_screening
    def auth_tree(%{auth_node: auth_node}), do: auth_node
    def apply_label(_), do: dgettext("eyra-zircon", "apply.cta.title")
    def open_label(_), do: dgettext("eyra-zircon", "open.cta.title")
    def ready?(tool), do: Zircon.Screening.ToolModel.ready?(tool)
    def form(_, _), do: Zircon.Screening.ToolForm

    def task_labels(_) do
      %{
        pending: dgettext("eyra-zircon", "pending.label"),
        participated: dgettext("eyra-zircon", "participated.label")
      }
    end

    def attention_list_enabled?(_t), do: false
    def group_enabled?(_t), do: false
  end

  defimpl Frameworks.Concept.Leaf do
    use Gettext, backend: CoreWeb.Gettext
    alias Frameworks.Concept
    def resource_id(%{id: id}), do: "zircon/#{id}"
    def tag(_), do: dgettext("eyra-zircon", "leaf.tag")

    def info(%{papers: papers}, _timezone) do
      paper_count = papers |> length()
      [dngettext("eyra-zircon", "1 paper", "* papers", paper_count)]
    end

    def status(_), do: %Concept.Leaf.Status{value: :private}
  end
end
