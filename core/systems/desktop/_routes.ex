defmodule Systems.Desktop.Routes do
  @moduledoc false
  defmacro routes() do
    quote do
      scope "/", Systems.Desktop do
        pipe_through([:browser, :require_authenticated_user])
        live("/desktop", Page)
      end
    end
  end
end
