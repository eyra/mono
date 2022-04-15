defmodule Systems.Admin.Routes do
  defmacro routes() do
    quote do
      scope "/admin", Systems.Admin do
        pipe_through([:browser])

        live("/login", LoginPage)
        live("/permissions", PermissionsPage)
      end
    end
  end
end
U
