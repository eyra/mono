defmodule CoreWeb.Live.Lab.Routes do
  defmacro routes() do
    quote do
      scope "/", CoreWeb do
        pipe_through([:browser, :require_authenticated_user])

        live("/lab/:id", Lab.Public)
      end
    end
  end
end
