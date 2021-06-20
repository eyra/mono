defmodule CoreWeb.Live.DataDonation.Routes do
  defmacro routes() do
    quote do
      scope "/", CoreWeb do
        pipe_through([:browser])

        #get("/data-donation/:id", DataDonationController, :index)
        live("/data-donation/:id/content", DataDonation.Content)
      end
    end
  end
end
