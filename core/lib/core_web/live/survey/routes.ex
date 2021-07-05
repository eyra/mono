defmodule CoreWeb.Live.Survey.Routes do
  defmacro routes() do
    quote do
      scope "/", CoreWeb do
        pipe_through([:browser, :require_authenticated_user])

        live("/survey/:id/content", Survey.Content)
        live("/survey/:id/complete", Survey.Complete)
      end
    end
  end
end
