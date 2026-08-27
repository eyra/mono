defmodule Systems.Lab.Routes do
  @moduledoc false
  defmacro routes() do
    quote do
      scope "/", Systems.Lab do
        pipe_through([:browser, :require_authenticated_user])

        live("/lab/:id", PublicPage)
      end
    end
  end
end
