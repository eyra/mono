defmodule Systems.DataDonation.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.DataDonation do
        pipe_through([:browser, :require_authenticated_user])

        live("/data-donation/:id/content", ContentPage)
        live("/data-donation/:id", Uploader)

        get("/data-donation/:id/download", DownloadController, :download_all)
        get("/data-donation/:id/download/:donation_id", DownloadController, :download_single)
      end
    end
  end
end
