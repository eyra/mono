defmodule CoreWeb.Live.DataDonation.Routes do
  defmacro routes() do
    quote do
      scope "/", CoreWeb do
        pipe_through([:browser, :require_authenticated_user])

        live("/data-donation/:id/content", DataDonation.Content)
        live("/data-donation/:id", DataDonation.Uploader)

        get("/data-donation/:id/download", DataDonationController, :download_all)
        get("/data-donation/:id/download/:donation_id", DataDonationController, :download_single)
      end
    end
  end
end
