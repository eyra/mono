defmodule Systems.DataDonation.DefaultController do
  use CoreWeb, :controller

  def donate(conn, params) do
    handle(conn, params, Systems.DataDonation.DonatePage)
  end

  def flow(conn, params) do
    handle(conn, params, Systems.DataDonation.FlowPage)
  end

  def port(
        conn,
        %{
          "participant" => participant
        }
      ) do
    unless String.match?(participant, ~r/[a-zA-Z0-9_\-]+/) do
      throw(:invalid_participant_id)
    end

    path =
      Routes.live_path(conn, Systems.DataDonation.PortPage, session: %{participant: participant})

    redirect(conn, to: path)
  end

  def handle(
        conn,
        %{
          "id" => id,
          "participant" => participant
        },
        page
      ) do
    unless String.match?(participant, ~r/[a-zA-Z0-9_\-]+/) do
      throw(:invalid_participant_id)
    end

    path = Routes.live_path(conn, page, id, session: %{participant: participant})

    redirect(conn, to: path)
  end
end
