defmodule Systems.Scholar.ExportController do
  use CoreWeb, :controller

  alias Systems.{
    Scholar,
    Pool
  }

  def credits(conn, %{"pool" => pool_id, "filters" => filters, "query" => query}) do
    %{name: pool_name, participants: students} =
      pool = Pool.Context.get!(pool_id, participants: [:features, :profile])

    filters = prepare_list(filters)
    query = prepare_list(query)

    filename_elements = [pool_name] ++ filters ++ query
    filename = "#{Enum.join(filename_elements, "_")}.csv"

    csv_data =
      students
      |> Scholar.Context.filter(filters, pool)
      |> Scholar.Context.query(query)
      |> export(pool)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
    |> put_root_layout(false)
    |> send_resp(200, csv_data)
  end

  defp prepare_list(""), do: []
  defp prepare_list(filters) when is_binary(filters), do: filters |> String.split(",")
  defp prepare_list(_), do: []

  def export(students, pool) do
    students
    |> Enum.map(
      &%{
        studentid:
          Core.SurfConext.get_surfconext_user_by_user(&1)
          |> Core.SurfConext.User.student_id(),
        email: &1.email,
        name: &1.profile.fullname,
        credits: Scholar.Context.credits(&1, pool)
      }
    )
    |> CSV.encode(headers: [:studentid, :email, :name, :credits])
    |> Enum.to_list()
  end
end
