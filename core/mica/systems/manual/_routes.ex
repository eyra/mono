defmodule Systems.Manual.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Manual do
        pipe_through([:browser, :require_authenticated_user])

        live("/manual/:id", Builder.PublicPage)
      end
    end
  end
end
