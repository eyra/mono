defmodule CoreWeb.Live.Study.Routes do
  defmacro routes() do
    quote do
      scope "/", CoreWeb do
        pipe_through([:browser, :require_authenticated_user])

        live("/studies/new", Study.New)
      end
    end
  end
end
