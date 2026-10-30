defmodule Next.Systems.Graphite.ExportController do
  use MicaWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: MicaWeb.Layouts], namespace: MicaWeb]}

  alias Next.Systems.{
    Graphite
  }

  def submissions(conn, %{"id" => id}) do
    leaderboard = Graphite.Public.get_leaderboard!(id)

    if authorized?(conn, leaderboard) do
      submissions(conn, leaderboard, id)
    else
      forbidden(conn)
    end
  end

  defp submissions(conn, leaderboard, id) do
    csv_data =
      leaderboard
      |> Graphite.Public.list_submissions()
      |> export()

    filename = "graphite-#{id}-submissions.csv"

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
    |> send_resp(200, csv_data)
  end

  defp authorized?(%{assigns: %{current_user: user}}, leaderboard),
    do: Mica.Authorization.can_access?(user, leaderboard, Graphite.LeaderboardContentPage)

  defp forbidden(conn) do
    conn
    |> put_status(:forbidden)
    |> put_view(html: MicaWeb.ErrorHTML)
    |> render(:"403")
  end

  def export(submissions) when is_list(submissions) do
    submissions
    |> Enum.map(&export/1)
    |> CSV.encode(headers: ["submission-id", "url", "ref"])
    |> Enum.to_list()
  end

  def export(%Graphite.SubmissionModel{id: submission_id} = submission) do
    {url, ref} = Graphite.SubmissionModel.repo_url_and_ref(submission)
    %{"submission-id" => "#{submission_id}", "url" => url, "ref" => ref}
  end
end
