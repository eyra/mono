defmodule Systems.DataDonation.Routes do
  defmacro routes() do
    quote do
      scope "/data-donation", Systems.DataDonation do
        pipe_through([:browser])
        get("/centerdata/:id", CenterdataController, :create)
        live("/centerdata/fakeapi/page", CenterdataFakeApiPage)
      end

      scope "/data-donation", Systems.DataDonation do
        pipe_through([:browser_unprotected])
        post("/centerdata/:id", CenterdataController, :create)
      end
    end
  end
end
