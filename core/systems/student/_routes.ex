defmodule Systems.Student.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Student do
        pipe_through([:browser, :require_authenticated_user])
        live("/student/:id", DetailPage)
      end
    end
  end
end
