defmodule Systems.DataDonation.Routes do
  defmacro routes() do
    quote do
      scope "/port", Systems.DataDonation do
        pipe_through([:browser, :require_authenticated_user])
      end

      scope "/port", Systems.DataDonation do
        pipe_through([:browser])

        get("/:id/:participant", DefaultController, :port)
        live("/:id", PortPage)
      end

      scope "/data-donation", Systems.DataDonation do
        pipe_through([:browser])

        get("/flow/:id/:participant", DefaultController, :flow)
        live("/flow/:id", FlowPage)

        live("/thankswhatsapp/:id/:participant", ThanksWhatsappPage)

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
