defmodule Systems.Benchmark.ExportController do
  use CoreWeb, :controller

  alias Systems.{
    Benchmark
  }

  @extract_owner_repo_and_ref ~r/https:\/\/github\.com\/(.*)\/commit\/([0-9a-f]{40})/
  @github_url_template "git@github.com:${owner_repo}.git"

  def submissions(conn, %{"id" => id}) do
    submissions = Benchmark.Public.list_submissions(id, [:spot])
    csv_data = export(submissions)

    filename = "benchmark-#{id}-submissions.csv"

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
    |> put_root_layout(false)
    |> send_resp(200, csv_data)
  end

  def export(submissions) when is_list(submissions) do
    submissions
    |> Enum.map(&export/1)
    |> CSV.encode(headers: [:id, :url, :ref])
    |> Enum.to_list()
  end

  def export(%Benchmark.SubmissionModel{
        id: submission_id,
        description: description,
        github_commit_url: github_commit_url,
        spot: %{name: name}
      }) do
    id = "#{submission_id}:#{name}:#{description}"

    case Regex.run(@extract_owner_repo_and_ref, github_commit_url) do
      [_, owner_repo, ref] ->
        url = String.replace(@github_url_template, "${owner_repo}", owner_repo)
        %{id: id, url: url, ref: ref}

      _ ->
        %{id: id, url: github_commit_url, ref: ""}
    end
  end
end
