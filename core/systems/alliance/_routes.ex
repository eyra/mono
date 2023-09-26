defmodule Systems.Alliance.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Alliance do
        pipe_through([:browser, :require_authenticated_user])
        live("/alliance/:id/callback", CallbackPage)
      end
    end
  end
end
