defmodule Systems.Advert.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Advert do
        pipe_through([:browser, :require_authenticated_user])
        live("/advert/:id/content", ContentPage)
      end
    end
  end
end
