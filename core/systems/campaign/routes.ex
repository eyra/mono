defmodule Systems.Campaign.Routes do
  defmacro routes() do
    quote do

      scope "/", Systems.Campaign do
        pipe_through([:browser, :require_authenticated_user])
        live("/campaign/:id/content", ContentPage)
        live("/recruitment", OverviewPage)
      end
    end
  end
end
