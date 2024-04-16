defmodule Systems.Graphite.SubmissionModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import CoreWeb.Gettext
  import Ecto.Changeset

  alias Systems.Graphite

  schema "graphite_submissions" do
    field(:description, :string)
    field(:github_commit_url, :string)

    belongs_to(:tool, Graphite.ToolModel)
    belongs_to(:auth_node, Core.Authorization.Node)
    has_many(:scores, Graphite.ScoreModel, foreign_key: :submission_id)

    timestamps()
  end

  @fields ~w(description github_commit_url)a
  @required_fields @fields
  @valid_github_commit_url ~r"https:\/\/github\.com(?:\/[^\/]+)*\/commits?\/[0-9a-f]{40}"

  def prepare(tool, params) do
    tool
    |> cast(params, @fields)
  end

  def change(tool, params) do
    tool
    |> cast(params, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
    |> validate_format(:github_commit_url, @valid_github_commit_url,
      message: dgettext("eyra-graphite", "invalid.github.commit.url.message")
    )
  end

  def preload_graph(:down), do: preload_graph([])
end
