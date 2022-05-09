defmodule Systems.DataDonation.DefaultController do
  use CoreWeb, :controller

  def create(
        conn,
        %{
          "flow" => flow,
          "participant" => participant
        }
      ) do
    unless String.match?(participant, ~r/[a-zA-Z0-9_\-]+/) do
      throw(:invalid_participant_id)
    end

    storage_info = %{participant: participant}

    conn
    |> live_render(Systems.DataDonation.UploadPage,
      session: %{"flow" => flow, "storage_info" => storage_info}
    )
  end
end
