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
    end
  end
end
