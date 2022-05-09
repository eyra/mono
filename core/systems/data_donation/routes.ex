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
        live("/donate", UploadPage)
        live("/thanks", ThanksPage)

        get("/:flow/donate/:participant", DefaultController, :create)
        get("/centerdata/:id", CenterdataController, :create)
      end

      scope "/data-donation", Systems.DataDonation do
        pipe_through([:browser_unprotected])
        post("/centerdata/:id", CenterdataController, :create)
      end
    end
  end
end
