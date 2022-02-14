defmodule Systems.DataDonation.Routes do
  defmacro routes() do
    quote do
      scope "/data-donation", Systems.DataDonation do
        pipe_through([:browser, :require_authenticated_user])

        live("/:id/content", ContentPage)

        get("/:id/download", DownloadController, :download_all)
        get("/:id/download/:donation_id", DownloadController, :download_single)
      end

      scope "/data-donation", Systems.DataDonation do
        pipe_through([:browser])
        live("/:participant_id", UploadPage)
        live("/thanks", ThanksPage)
      end
    end
  end
end
