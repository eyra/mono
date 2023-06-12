defmodule Systems.Benchmark.SpotModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.{
    Benchmark
  }

  schema "benchmark_spots" do
    field(:name, :string, default: "")
    has_many(:submissions, Benchmark.SubmissionModel, foreign_key: :spot_id)
    belongs_to(:tool, Benchmark.ToolModel)
    belongs_to(:auth_node, Core.Authorization.Node)

    timestamps()
  end

  @fields ~w(name)a
  @required_fields ~w()a

  def changeset(tool, params) do
    tool
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end

  def preload_graph(:down),
    do:
      preload_graph([
        :auth_node,
        :submissions
      ])

  def preload_graph(:auth_node), do: [auth_node: []]

  def preload_graph(:submissions),
    do: [submissions: Benchmark.SubmissionModel.preload_graph(:down)]

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(spot), do: spot.auth_node_id
  end

  defimpl Frameworks.Utility.ViewModelBuilder do
    use CoreWeb, :verified_routes

    import CoreWeb.Gettext

    @max_submissions 3

    def view_model(%Benchmark.SpotModel{} = spot, page, %{active?: active?, myself: target}) do
      vm(spot, page, target, active?)
    end

    defp vm(%{submissions: submissions}, Systems.Benchmark.SubmissionListForm, target, active?) do
      items = Enum.map(submissions, &map_to_item(&1, target, active?))

      add_button =
        if active? and Enum.count(submissions) < @max_submissions do
          %{
            action: %{type: :send, event: "add"},
            face: %{type: :primary, label: dgettext("eyra-benchmark", "add.submission.button")}
          }
        else
          nil
        end

      subhead =
        if active? do
          dgettext("eyra-benchmark", "submissions.subhead.active")
        else
          dgettext("eyra-benchmark", "submissions.subhead.inactive")
        end

      %{
        title: dgettext("eyra-benchmark", "submissions.title"),
        intro: dgettext("eyra-benchmark", "submissions.intro"),
        subhead: subhead,
        add_button: add_button,
        items: items
      }
    end

    defp map_to_item(
           %{
             id: id,
             description: description,
             updated_at: updated_at,
             github_commit_url: github_commit_url
           },
           target,
           active?
         ) do
      summary =
        updated_at
        |> CoreWeb.UI.Timestamp.apply_timezone()
        |> CoreWeb.UI.Timestamp.humanize()
        |> Macro.camelize()

      buttons =
        if active? do
          [
            edit_button(id, target),
            remove_button(id, target)
          ]
        else
          []
        end

      %{
        id: id,
        description: description,
        summary: summary,
        url: github_commit_url,
        buttons: buttons
      }
    end

    defp edit_button(id, target) do
      %{
        action: %{type: :send, item: id, target: target, event: "edit"},
        face: %{type: :icon, icon: :edit}
      }
    end

    defp remove_button(id, target) do
      %{
        action: %{type: :send, item: id, target: target, event: "remove"},
        face: %{type: :icon, icon: :remove}
      }
    end
  end
end
