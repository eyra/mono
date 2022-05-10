defmodule Systems.DataDonation.DefaultController do
  use CoreWeb, :controller

  def create(
        conn,
        %{
          "id" => id,
          "participant" => participant
        }
      ) do
    unless String.match?(participant, ~r/[a-zA-Z0-9_\-]+/) do
      throw(:invalid_participant_id)
    end

    path =
      Routes.live_path(conn, Systems.DataDonation.UploadPage, id,
        session: %{participant: participant}
      )

    redirect(conn, to: path)
  end
end
