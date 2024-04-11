defmodule Systems.Graphite.ExportController do
  use CoreWeb, :controller

  alias Systems.{
    Graphite
  }

  @extract_owner_repo_and_ref_basic ~r/https:\/\/github\.com\/(.*)\/commit\/([0-9a-f]{40})$/
  @extract_owner_repo_and_ref_pull ~r/https:\/\/github\.com\/(.*)\/pull\/\d+\/commits?\/([0-9a-f]{40})$/
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

    {url, ref} = extract(github_commit_url)
    %{id: id, description: description, url: url, ref: ref}
  end

  defp extract(url) do
    if String.contains?(url, "/pull/") do
      extract(@extract_owner_repo_and_ref_pull, url)
    else
      extract(@extract_owner_repo_and_ref_basic, url)
    end
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
