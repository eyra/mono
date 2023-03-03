defmodule Systems.Citizen.Routes do
  defmacro routes() do
    quote do
      scope "/", Systems.Citizen do
        pipe_through([:browser, :require_authenticated_user])
      end
    end
  end
end
