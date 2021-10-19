defmodule Systems.Crew.Routes do
  defmacro routes() do
    quote do

      scope "/", Systems.Crew do
        pipe_through([:browser, :require_authenticated_user])
        live("/task/:id", TaskPage)
        live("/task/:id/callback", TaskCompletePage)
      end
    end
  end
end
