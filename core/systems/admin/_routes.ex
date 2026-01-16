defmodule Systems.Admin.Routes do
  defmacro routes() do
    quote do
      scope "/admin", Systems.Admin do
        pipe_through([:browser])

        live("/login", LoginPage)
        live("/config", ConfigPage)
        live("/typography", TypographyPage)
      end
    end
  end
end
