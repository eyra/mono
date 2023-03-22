defmodule Systems.Admin.Routes do
  defmacro routes() do
    quote do
      scope "/admin", Systems.Admin do
        pipe_through([:browser])

        live("/login", LoginPage)
        live("/config", ConfigPage)
        live("/import/rewards", ImportRewardsPage)
      end
    end
  end
end
