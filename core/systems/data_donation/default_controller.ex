defmodule Systems.DataDonation.DefaultController do
  use CoreWeb, :controller

  def donate(conn, params) do
    handle(conn, params, Systems.DataDonation.DonatePage)
  end

  def flow(conn, params) do
    handle(conn, params, Systems.DataDonation.FlowPage)
  end

  def port(conn, params) do
    handle(conn, params, Systems.DataDonation.PortPage)
  end

  def handle(
        conn,
        %{
          "id" => id,
          "participant" => participant
        },
        page
      ) do
    options =
      Plug.Conn.fetch_query_params(conn)
      |> options(participant)

    unless String.match?(participant, ~r/[a-zA-Z0-9_\-]+/) do
      throw(:invalid_participant_id)
    end

    path = Routes.live_path(conn, page, id, options)

    redirect(conn, to: path)
  end

  defp options(conn, participant) do
    options(conn) ++ [session: %{participant: participant}]
  end

  defp options(%{query_params: %{"locale" => locale}}), do: [locale: locale]
  defp options(_), do: []
end
