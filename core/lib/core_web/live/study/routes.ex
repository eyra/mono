defmodule CoreWeb.Live.Study.Routes do
  defmacro routes() do
    quote do
      scope "/", CoreWeb do
        pipe_through([:browser, :require_authenticated_user])

        live("/studies/new", Study.New)
        live("/studies/:id", Study.Public)
        live("/studies/:id/edit", Study.Edit)
        live("/studies/:id/complete", Study.Complete)
      end
    end
  end
end
