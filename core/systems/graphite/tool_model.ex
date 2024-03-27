defmodule Systems.Graphite.ToolModel do
  @moduledoc """
  The benchmark tool schema.
  """
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  import CoreWeb.Gettext

  alias Systems.Graphite

  schema "graphite_tools" do
    belongs_to(:auth_node, Core.Authorization.Node)
    has_many(:submissions, Graphite.SubmissionModel, foreign_key: :tool_id)

    timestamps()
  end

  @fields ~w()a
  @required_fields @fields

  def changeset(tool, params) do
    tool
    |> cast(params, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:down),
    do:
      preload_graph([
        :submissions,
        :auth_node
      ])

  def preload_graph(:auth_node), do: [auth_node: []]

  def preload_graph(:submissions),
    do: [submissions: Graphite.SubmissionModel.preload_graph(:down)]

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(tool), do: tool.auth_node_id
  end

  def ready?(tool) do
    changeset =
      changeset(tool, %{})
      |> validate()

    changeset.valid?()
  end

  defimpl Frameworks.Concept.ToolModel do
    alias Systems.Graphite
    def key(_), do: :graphite
    def auth_tree(%{auth_node: auth_node}), do: auth_node
    def apply_label(_), do: ""
    def open_label(_), do: ""
    def ready?(_), do: true
    def form(_, _), do: Graphite.ToolForm

    def launcher(tool) do
      %{
        module: Graphite.ToolView,
        params: %{
          tool: tool
        }
      }
    end

    def task_labels(_) do
      %{
        pending: dgettext("eyra-graphite", "pending.label"),
        participated: dgettext("eyra-graphite", "participated.label")
      }
    end

    def attention_list_enabled?(_t), do: false
    def group_enabled?(_t), do: false
  end
end
