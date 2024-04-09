defmodule Systems.Graphite.ExportController do
  use CoreWeb, :controller

  alias Systems.{
    Graphite
  }

  @extract_owner_repo_and_ref ~r/https:\/\/github\.com\/(.*)\/commit\/([0-9a-f]{40})/
  @github_url_template "git@github.com:${owner_repo}.git"

  def submissions(conn, %{"id" => id}) do
    submissions =
      Graphite.Public.get_leaderboard!(id)
      |> Graphite.Public.list_submissions()

    csv_data = export(submissions)

    filename = "graphite-#{id}-submissions.csv"

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
    |> send_resp(200, csv_data)
  end

  def export(submissions) when is_list(submissions) do
    submissions
    |> Enum.map(&export/1)
    |> CSV.encode(headers: [:id, :url, :ref])
    |> Enum.to_list()
  end

  def export(%Graphite.SubmissionModel{
        id: submission_id,
        description: description,
        github_commit_url: github_commit_url,
        auth_node: _auth_node
      }) do
    # TODO: fetch name of collab out of auth_node
    id = "#{submission_id}"

    case Regex.run(@extract_owner_repo_and_ref, github_commit_url) do
      [_, owner_repo, ref] ->
        url = String.replace(@github_url_template, "${owner_repo}", owner_repo)
        %{id: id, description: description, url: url, ref: ref}

      _ ->
        %{id: id, url: github_commit_url, ref: ""}
    end
  end
end
