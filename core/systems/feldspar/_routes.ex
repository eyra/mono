defmodule Systems.Feldspar.Routes do
  defmacro routes() do
    quote do
      scope "/feldspar", Systems.Feldspar do
        pipe_through([:browser])
        live("/apps/:id", AppPage)
      end

      scope "/api/feldspar", Systems.Feldspar do
        pipe_through([:api])
        post("/donate", DataDonationController, :create)
      end
    end
  end
end
