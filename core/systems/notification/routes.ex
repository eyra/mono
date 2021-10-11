defmodule Systems.Notification.Routes do
  defmacro routes() do
    quote do

      scope "/", Systems.Notification do
        pipe_through([:browser, :require_authenticated_user])
        live("/notifications", OverviewPage)
      end
    end
  end
end
