defmodule Systems.Graphite.SubmissionModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import CoreWeb.Gettext
  import Ecto.Changeset

  alias Systems.Graphite

  @github_url_template "git@github.com:${owner_repo}.git"

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
  @valid_github_commit_url ~r"https:\/\/github\.com\/(\w+\/\w+)(?:\/pull\/\d+)?\/commits?\/([0-9a-f]{40})\/?$"

  def valid_github_commit_url(), do: @valid_github_commit_url

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

  def repo_url_and_ref(%__MODULE__{github_commit_url: github_commit_url}) do
    extract(Graphite.SubmissionModel.valid_github_commit_url(), github_commit_url)
  end

  defp extract(regex, url) do
    case Regex.run(regex, url) do
      [_, owner_repo, ref] ->
        url = String.replace(@github_url_template, "${owner_repo}", owner_repo)
        {url, ref}

      _ ->
        {url, ""}
    end
  end
end
